//
//  IndexCommand.swift
//  Command
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation

struct IndexCommand : AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "index")
    
    @OptionGroup
    private var shared: SharedArguments
    
    mutating func run() async throws {
        let generator = try shared.generator
        try await generator.loadMetadata(including: shared.regionsToInclude)
        try await generator.generateIndices()
    }
}
