//
//  Generator+Metadata.swift
//  Generator
//
//  Created by Lucka on 24/10/2024.
//

import Foundation
import OverpassKit

public extension Generator {
    var missingWikidata: [ Region ] {
        regions { $0.wikidataIdentifier == nil }
    }
    
    func ensureMetadata(
        with api: Overpass, cooldown: Duration, including regions: Set<Region.Code>?
    ) async throws {
        try await ensureCountries(with: api, cooldown: cooldown)
        let filter = RegionFilter(regions)
        if let filter {
            countries = countries.filter(filter.filter(country:))
        }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in countries.indices {
                group.addTask {
                    try await self.ensureSubdivisionsOfCountry(
                        at: index, with: api, cooldown: cooldown, filterBy: filter
                    )
                }
            }
            try await group.waitForAll()
        }
    }
    
    func loadMetadata(including regions: Set<Region.Code>? = nil) throws {
        try loadCountries()
        let filter = RegionFilter(regions)
        if let filter {
            countries = countries.filter(filter.filter(country:))
        }
        for index in countries.indices {
            let countryCode = countries[index].code
            guard !Self.countriesWithoutSubdivisionDefined.contains(countryCode.rawValue) else {
                continue
            }
            countries[index].subdivisions = try loadSubdivisions(of: countryCode, filterBy: filter)
        }
    }
}

extension Generator {
    nonisolated var countryMetadataFileURL: URL {
        metadataDirectory
            .appending(component: "countries")
            .appendingPathExtension("json")
    }
    
    nonisolated var metadataSubdivisionsDirectory: URL {
        metadataDirectory.appending(path: "subdivisions")
    }
    
    nonisolated var metadataDirectory: URL {
        workingDirectory.appending(component: "metadata")
    }
    
    nonisolated func subdivisionMetadataFileURL(of regionCode: Region.Code) -> URL {
        metadataSubdivisionsDirectory
            .appending(component: regionCode.rawValue)
            .appendingPathExtension("json")
    }
}

fileprivate extension Generator {
    enum MetadataError: Error {
        case unableToFetchSubdivision(code: Region.Code)
        case invalidTag(code: Region.Code, tag: String)
    }
    
    static let countriesWithoutSubdivisionDefined: Set<String> = [
        "AI", "AQ", "AS", "AW", "AX",
        "BL", "BM", "BV",
        "CC", "CK", "CW", "CX",
        "FK", "FO",
        "GF", "GG", "GI", "GP", "GS", "GU",
        "HK", "HM",
        "IM", "IO",
        "JE",
        "KY",
        "MF", "MO", "MP", "MQ", "MS",
        "NC", "NF", "NU",
        "PF", "PM", "PN", "PR",
        "RE",
        "SX",
        "TC", "TF", "TK",
        "VA", "VG", "VI",
        "XK",
        "YT"
    ]
    
    func ensureCountries(with api: Overpass, cooldown: Duration) async throws {
        let file = countryMetadataFileURL
        guard !FileManager.default.fileExists(atPath: file.path()) else {
            try loadCountries()
            return
        }
        
        countries = try await fetchCountries(with: api, cooldown: cooldown)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted, .sortedKeys, .withoutEscapingSlashes
        ]
        try encoder.encode(countries).write(to: file)
    }
    
    func ensureSubdivisionsOfCountry(
        at index: Int, with api: Overpass, cooldown: Duration, filterBy filter: RegionFilter?
    ) async throws {
        let country = countries[index]
        guard !Self.countriesWithoutSubdivisionDefined.contains(country.code.rawValue) else {
            return
        }
        
        let file = subdivisionMetadataFileURL(of: country.code)
        guard !FileManager.default.fileExists(atPath: file.path()) else {
            countries[index].subdivisions = try loadSubdivisions(of: country.code, filterBy: filter)
            return
        }
        
        var subdivisions = try await fetchSubdivision(of: country, with: api, cooldown: cooldown)
        
        guard !subdivisions.isEmpty else {
            throw MetadataError.unableToFetchSubdivision(code: country.code)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [ .prettyPrinted, .sortedKeys, .withoutEscapingSlashes ]
        try encoder.encode(subdivisions).write(to: file)
        
        if let filter {
            subdivisions = subdivisions.filter(filter.filter(region:))
        }
        
        countries[index].subdivisions = subdivisions
    }
    
    func loadCountries() throws {
        countries = try JSONDecoder()
            .decode([ Region ].self, from: try .init(contentsOf: countryMetadataFileURL))
    }
    
    func loadSubdivisions(of countryCode: Region.Code, filterBy filter: RegionFilter?) throws -> [ Region ] {
        var subdivisions = try JSONDecoder()
            .decode(
                [ Region ].self,
                from: try .init(contentsOf: subdivisionMetadataFileURL(of: countryCode))
            )
        if let filter {
            subdivisions = subdivisions.filter(filter.filter(region:))
        }
        return subdivisions
    }
    
    nonisolated func fetchCountries(
        with api: Overpass, cooldown: Duration
    ) async throws -> [ Region ] {
        /* Query countries */
        /*
         [out:json];
         relation["admin_level"="2"]["ISO3166-1"]["type"!="land_area"]->.countries;
         relation(r.countries:"subarea")->.subareas;
         (
           .countries;
           relation.subareas["ISO3166-1"];
           relation(r.subareas:"subarea")["ISO3166-1"];
           relation["ISO3166-1"="AQ"]; // Antarctica
         )->.countries;
         foreach.countries
         {
             convert Country
                 ::id = id(),
                 code = t["ISO3166-1"],
                 wikidata = t["wikidata"];
             out;
         };
         out tags;
         */
        try await taskGroup.addTask(cooldown: cooldown) {
            try await api.query(Region.Element.self) {
                Elements(.relation) {
                    FilterBy(tag: "admin_level", equals: "2")
                    FilterBy(tag: "ISO3166-1", exists: true)
                    FilterBy(tag: "type", notEquals: "land_area")
                }
                .as("countries")
                Elements(.relation) {
                    Recurse(into: .relations, of: "countries", by: "subarea")
                }
                .as("subareas")
                
                Union {
                    Elements(set: "countries")
                    Elements(.relation, in: "subareas") {
                        FilterBy(tag: "ISO3166-1", exists: true)
                    }
                    Elements(.relation) {
                        Recurse(into: .relations, of: "subareas", by: "subarea")
                        FilterBy(tag: "ISO3166-1", exists: true)
                    }
                    Elements(.relation) {
                        FilterBy(tag: "ISO3166-1", equals: "AQ")
                    }
                }
                .as("countries")
                
                ForEach("countries") {
                    Convert(typeName: "Country") {
                        ConvertAsId()
                        ConvertAsTag("code", by: .tag("ISO3166-1"))
                        ConvertAsTag("wikidata", by: .tag("wikidata"))
                    }
                    
                    Output()
                }
                
                Output(verbosity: .tags)
            }
            .map {
                guard !$0.tags.wikidata.isEmpty else {
                    throw MetadataError.invalidTag(code: $0.tags.code, tag: "wikidata")
                }
                return .init(element: $0)
            }
        }
    }
    
    nonisolated func fetchSubdivision(
        of country: Region, with api: Overpass, cooldown: Duration
    ) async throws -> [ Region ] {
         /* Query first administrations */
        /*
         [out:json];
         relation(id)->.country;
         relation(r.country:"subarea")[!"ISO3166-1"]->.subareas;
         // Virtual subareas contianing the real subdivisions, like RU and NO
         relation.subareas[!"ISO3166-2"]->.virtual_subareas;
         (
           relation.subareas["ISO3166-2"];
           relation(r.virtual_subareas:"subarea")[!"ISO3166-1"]["ISO3166-2"];
         )->.regions;
         // Use collections to present boundaries, like CD
         if (regions.count(relations)==0) {
           relation.subareas["collection"="boundary"]["boundary"!="historic"]->.collection;
           relation(r.collection)[!"ISO3166-1"]["ISO3166-2"]->.regions;
         };
         foreach.regions
         {
             convert Region
                 ::id = id(),
                 code = t["ISO3166-2"],
                 wikidata = t["wikidata"];
             out;
         };
         out tags;
         */
        try await taskGroup.addTask(cooldown: cooldown) {
            try await api.query(Region.Element.self) {
                Elements(.relation) {
                    FilterBy(id: country.id)
                }
                .as("country")
                
                Elements(.relation) {
                    Recurse(into: .relations, of: "country", by: "subarea")
                    FilterBy(tag: "ISO3166-1", exists: false)
                }
                .as("subareas")
                Elements(.relation, in: "subareas") {
                    FilterBy(tag: "ISO3166-2", exists: false)
                }
                .as("virtual_subareas")
                
                Union {
                    Elements(.relation, in: "subareas") {
                        FilterBy(tag: "ISO3166-2", exists: true)
                    }
                    Elements(.relation) {
                        Recurse(into: .relations, of: "virtual_subareas")
                        FilterBy(tag: "ISO3166-1", exists: false)
                        FilterBy(tag: "ISO3166-2", exists: true)
                    }
                }
                .as("regions")
                
                Optionally(.count(.relations, in: "regions").equals(0)) {
                    Elements(.relation, in: "subarea") {
                        FilterBy(tag: "collection", equals: "boundary")
                        FilterBy(tag: "boundary", notEquals: "historic")
                    }
                    .as("collection")
                    Elements(.relation) {
                        Recurse(into: .relations, of: "collection")
                        FilterBy(tag: "ISO3166-1", exists: false)
                        FilterBy(tag: "ISO3166-2", exists: true)
                    }
                    .as("regions")
                }
                
                ForEach("regions") {
                    Convert(typeName: "Region") {
                        ConvertAsId()
                        ConvertAsTag("code", by: .tag("ISO3166-2"))
                        ConvertAsTag("wikidata", by: .tag("wikidata"))
                    }
                    
                    Output()
                }
                
                Output(verbosity: .tags)
            }
            .map {
                guard !$0.tags.wikidata.isEmpty else {
                    throw MetadataError.invalidTag(code: $0.tags.code, tag: "wikidata")
                }
                return .init(element: $0)
            }
        }
    }
}

fileprivate struct RegionFilter {
    let countires: Set<Region.Code>
    let regions: Set<Region.Code>
    
    init?(_ regions: Set<Region.Code>?) {
        guard let regions else {
            return nil
        }
        
        self.countires = regions.reduce(into: .init()) { result, item in
            switch item {
            case .country(_):
                result.insert(item)
            case .subdivision(let countryCode, _):
                result.insert(.country(code: countryCode))
            }
        }
        self.regions = regions
    }
    
    func filter(country: Region) -> Bool {
        countires.contains(country.code)
    }
    
    func filter(region: Region) -> Bool {
        regions.contains { $0.contains(region.code) }
    }
}
