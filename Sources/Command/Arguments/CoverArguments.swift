//
//  CoverArguments.swift
//  Command
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation
import SphereGeometry

struct CoverArguments : ParsableArguments {
    @Flag(name: [ .long ], inversion: .prefixedNo)
    var compress: Bool = true
    
    @Option
    var level: Level = .at.20
}
