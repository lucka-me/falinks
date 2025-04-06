//
//  WikidataArguments.swift
//  Falinks
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation

struct WikidataArguments : ParsableArguments {
    @Option(parsing: .upToNextOption)
    var locales: [ Locale ] = [ .init(identifier: "en") ]
}
