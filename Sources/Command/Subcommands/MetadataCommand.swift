//
//  MetadataCommand.swift
//  Command
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation
import Generator
import OverpassKit

struct MetadataCommand : AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "metadata")
    
    @OptionGroup
    private var overpass: OverpassArguments

    @OptionGroup
    private var shared: SharedArguments

    mutating func run() async throws {
        try await shared.generator.ensureMetadata(
            with: overpass.overpass,
            cooldown: overpass.cooldownDuration,
            including: shared.regionsToInclude
        )
    }
}
