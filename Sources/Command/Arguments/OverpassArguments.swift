//
//  OverpassArguments.swift
//  Command
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation
import OverpassKit

struct OverpassArguments : ParsableArguments {
    @Option(help: .init(valueName: "seconds"))
    var cooldown: Double = 10

    @Option(name: .customLong("overpass-api"), transform: { try .init($0, strategy: .url) })
    var api: URL = Overpass.defaultAPI
}

extension OverpassArguments {
    var cooldownDuration: Duration {
        .seconds(cooldown)
    }
    
    var overpass: Overpass {
        .init(api: api)
    }
}
