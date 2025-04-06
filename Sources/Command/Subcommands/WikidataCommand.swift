//
//  WikidataCommand.swift
//  Command
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation
import OverpassKit

struct WikidataCommand : AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "wikidata")
    
    @OptionGroup
    private var shared: SharedArguments
    
    @OptionGroup
    private var wikidata: WikidataArguments
    
    mutating func run() async throws {
        let generator = try shared.generator
        try await generator.loadMetadata(including: shared.regionsToInclude)
        try await generator.loadWikidata(including: wikidata.locales)
    }
}
