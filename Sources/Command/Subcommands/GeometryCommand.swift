//
//  GeometryCommand.swift
//  Command
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation

struct GeometryCommand : AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "geometry")
    
    @OptionGroup
    private var geometry: GeometryArguments
    
    @OptionGroup
    private var overpass: OverpassArguments
    
    @OptionGroup
    private var shared: SharedArguments
    
    mutating func run() async throws {
        let generator = try shared.generator
        try await generator.loadMetadata(including: shared.regionsToInclude)
        
        try await generator.ensureGeometries(
            with: overpass.overpass,
            cooldown: overpass.cooldownDuration,
            omitting: geometry.omits
        )
    }
}
