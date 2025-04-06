//
//  AllCommand.swift
//  Falinks
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation
import Generator
import OverpassKit
import SphereGeometry

struct AllCommand : AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "all")
    
    @OptionGroup
    private var cover: CoverArguments
    
    @OptionGroup
    private var geometry: GeometryArguments
    
    @OptionGroup
    private var overpass: OverpassArguments

    @OptionGroup
    private var shared: SharedArguments
    
    @OptionGroup
    private var wikidata: WikidataArguments
    
    mutating func run() async throws {
        let generator = try shared.generator
        
        print("Generating metadata...")
        try await generator.ensureMetadata(
            with: overpass.overpass,
            cooldown: overpass.cooldownDuration,
            including: shared.regionsToInclude
        )
        
        print("Generating geometries...")
        try await generator.ensureGeometries(
            with: overpass.overpass,
            cooldown: overpass.cooldownDuration,
            omitting: geometry.omits
        )
        
        print("Generating covers...")
        try await generator.ensureCovers(at: cover.level, compress: cover.compress)
        
        print("Generating indices...")
        try await generator.generateIndices()
        
        print("Generating wikidata...")
        try await generator.loadWikidata(including: wikidata.locales)
    }
}
