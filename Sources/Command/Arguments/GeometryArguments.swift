//
//  GeometryArguments.swift
//  Command
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation
import Generator
import OverpassKit

struct GeometryArguments : ParsableArguments {
    @Flag
    var omitUnownedInners: Bool = false
    
    @Option(parsing: .upToNextOption)
    var omitSegments: [ UInt64 ] = [ ]
    
    @Option
    var omitCoastlines: Generator.Omit.Coastline? = nil
}

extension GeometryArguments {
    var omits: Generator.Omit {
        .init(
            coastlines: omitCoastlines,
            segments: .init(omitSegments),
            unownedInners: omitUnownedInners
        )
    }
}

extension Generator.Omit.Coastline : ExpressibleByArgument {
}
