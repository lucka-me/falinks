//
//  Generator+Wikidata.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 21/10/2024.
//

import Foundation

public extension Generator {
    func loadWikidata(including languages: Set<String>) async throws {
        let entities = try await withThrowingTaskGroup(of: RegionEntity?.self) { group in
            for country in self.countries {
                group.addTask {
                    try await self.loadWikidata(of: country, including: languages)
                }
                if let subdivisions = country.subdivisions {
                    for subdivision in subdivisions {
                        group.addTask {
                            try await self.loadWikidata(of: subdivision, including: languages)
                        }
                    }
                }
            }
            
            var entities: [ Region.Code : RegionEntity ] = [ : ]
            for try await entity in group {
                guard let entity else {
                    continue
                }
                entities[entity.code] = entity
            }
            
            return entities
        }
        
        var stringCatalog = StringCatalog(
            strings: entities.reduce(into: .init()) { strings, entity in
                strings[entity.key.rawValue] = .init(
                    localizations: entity.value.localizations
                        .reduce(into: .init()) { items, element in
                            items[element.key] = .init(stringUnit: .init(value: element.value))
                        }
                )
            }
        )
        
        let localizationFile = wikidataDirectory
            .appending(component: "regions")
            .appendingPathExtension("xcstrings")
        
        if FileManager.default.fileExists(atPath: localizationFile.path(percentEncoded: false)) {
            stringCatalog.strings.merge(
                try JSONDecoder().decode(StringCatalog.self, from: try .init(contentsOf: localizationFile)).strings
            ) { currentItem, newItem in
                .init(
                    localizations: currentItem.localizations.merging(newItem.localizations) { currentLocalization, _ in
                        currentLocalization
                    }
                )
            }
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [ .prettyPrinted, .sortedKeys ]
        try encoder.encode(stringCatalog).write(to: localizationFile)
    }
}

extension Generator {
    nonisolated var wikidataFlagsDirectory: URL {
        wikidataDirectory.appending(component: "flags")
    }
    
    nonisolated var wikidataDirectory: URL {
        workingDirectory.appending(component: "wikidata")
    }
    
    nonisolated var wikidataRawDirectory: URL {
        wikidataDirectory.appending(component: "raw")
    }
    
    nonisolated func wikidataRawFileURL(of regionCode: Region.Code) -> URL {
        wikidataRawDirectory
            .appending(component: regionCode.rawValue)
            .appendingPathExtension("json")
    }
}

fileprivate extension Generator {
    static let wikidataEntityDataURL = URL(string: "https://wikidata.org/wiki/Special:EntityData")!
    static let wikimediaURL = URL(string: "https://commons.wikimedia.org/w/index.php")!
    
    func loadWikidata(of region: Region, including languages: Set<String>) async throws -> RegionEntity? {
        guard let wikidataIdentifier = region.wikidataIdentifier else {
            return nil
        }
        
        let fileManager = FileManager.default
        
        let rawFile = wikidataRawFileURL(of: region.code)
        let entity: Entity?
        if fileManager.fileExists(atPath: rawFile.path(percentEncoded: false)) {
            entity = try JSONDecoder()
                .decode(EntityData.self, from: try .init(contentsOf: rawFile))
                .entities.first?.value
        } else {
            let (data, _) = try await taskGroup.addTask {
                try await URLSession.shared.data(
                    from: Self.wikidataEntityDataURL
                        .appending(component: wikidataIdentifier)
                        .appendingPathExtension("json")
                )
            }
            entity = try JSONDecoder()
                .decode(EntityData.self, from: data)
                .entities.first?.value // It's possibly be redirected
            try data.write(to: rawFile)
        }
        
        guard let entity else {
            print("Entity is missing for \(region.code) \(wikidataIdentifier)")
            return nil
        }
        
        if let flagImageFilename = entity.flagImageFilename {
            let fileExtension = NSString(string: flagImageFilename).pathExtension.lowercased()
            let flagImageFile = wikidataFlagsDirectory
                .appending(component: region.code.rawValue)
                .appendingPathExtension(fileExtension)
            
            if !fileManager.fileExists(atPath: flagImageFile.path(percentEncoded: false)) {
                let (temporaryFileURL, _) = try await taskGroup.addTask {
                    try await URLSession.shared.download(
                        from: Self.wikimediaURL.appending(
                            queryItems: [
                                .init(name: "title", value: "Special:Redirect/file/\(flagImageFilename)")
                            ]
                        )
                    )
                }
                
                try fileManager.moveItem(at: temporaryFileURL, to: flagImageFile)
            }
        }
        
        return .init(
            code: region.code,
            localizations: entity.labels
                .filter { languages.isEmpty || languages.contains($0.key) }
                .reduce(into: .init()) { $0[$1.key] = $1.value.value }
        )
    }
}

fileprivate struct Claim<Value: Decodable> : Decodable {
    struct DataValue: Decodable {
        var value: Value
    }
    
    struct Snak : Decodable {
        var datavalue: DataValue?
    }
    
    var mainsnak: Snak
    var rank: String
}

fileprivate struct ClaimDirectory : Decodable {
    var flagImage: [ Claim<String> ]?
    
    enum CodingKeys : String, CodingKey {
        case flagImage = "P41"
    }
}

fileprivate struct EntityData : Decodable {
    var entities: [ String : Entity ]
}

fileprivate struct Entity : Decodable {
    var labels: [ String : Label ]
    var claims: ClaimDirectory
}

fileprivate struct RegionEntity : Sendable {
    let code: Region.Code
    let localizations: [ String : String ]
}

fileprivate struct StringCatalog : Codable {
    var sourceLanguage: String = "en"
    var version: String = "1.0"
    var strings: [ String : Item ]
}

fileprivate extension Entity {
    struct Label : Decodable {
        var language: String
        var value: String
    }
    
    var flagImageFilename: String? {
        guard
            let claims = claims.flagImage,
            let preferredClaim = claims.first(where: { $0.rank == "preferred" }) ?? claims.first
        else {
            return nil
        }
        
        return preferredClaim.mainsnak.datavalue?.value
    }
}

fileprivate extension StringCatalog {
    struct Item : Codable {
        var extractionState: String = "manual"
        var localizations: [ String : LocalizationItem ]
    }
    
    struct LocalizationItem: Codable {
        var stringUnit: StringUnit
    }
    
    struct StringUnit : Codable {
        var state: String = "translated"
        var value: String
    }
}
