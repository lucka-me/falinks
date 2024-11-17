//
//  ListCommand.swift
//  Falinks
//
//  Created by Lucka on 6/11/2024.
//

import ArgumentParser
import Foundation
import Generator

struct ListCommand : AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list")
    
    @Argument
    private var target: ListTarget
    
    @OptionGroup
    private var shared: SharedArguments
    
    mutating func run() async throws {
        let generator = try shared.generator
        try await generator.loadMetadata(including: shared.regionsToInclude)
        
        let fileManager = FileManager.default
        let regions: [ Region ]
        switch target {
        case .missingGeometry:
            regions = await generator.regions {
                !fileManager.fileExists(atPath: generator.geometryFileURL(of: $0.code).path())
            }
        case .missingCovers:
            regions = await generator.regions {
                !fileManager.fileExists(atPath: generator.rawCellFileURL(of: $0.code).path())
            }
        case .missingWikidata:
            regions = await generator.regions {
                $0.wikidataIdentifier == nil
            }
        }
        
        for region in regions {
            print(region.code)
        }
    }
}

fileprivate enum ListTarget : String, CaseIterable, ExpressibleByArgument {
    case missingGeometry = "missing-geometry"
    case missingCovers = "missing-covers"
    case missingWikidata = "missing-wikidata"
}
