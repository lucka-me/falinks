//
//  WikidataArguments.swift
//  Falinks
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser

struct WikidataArguments : ParsableArguments {
    @Option(parsing: .upToNextOption)
    var languages: [ String ] = [ "en" ]
}

extension WikidataArguments {
    var languagesToInclude: Set<String> {
        .init(languages)
    }
}
