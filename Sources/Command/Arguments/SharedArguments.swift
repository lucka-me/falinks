//
//  SharedArguments.swift
//  Command
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation
import Generator

struct SharedArguments : ParsableArguments {
    @Option(parsing: .upToNextOption)
    var regions: [ Region.Code ] = [ ]

    @Option
    var tasks: Int = 6
    
    @Option(
        name: [ .long, .customShort("d") ],
        completion: .directory,
        transform: { URL(filePath: $0) }
    )
    var workingDirectory: URL
}

extension SharedArguments {
    var generator: Generator {
        get throws {
            try Generator(
                workingDirectory: workingDirectory,
                maxTasks: tasks
            )
        }
    }
    
    var regionsToInclude: Set<Region.Code>? {
        regions.isEmpty ? nil : .init(regions)
    }
}
