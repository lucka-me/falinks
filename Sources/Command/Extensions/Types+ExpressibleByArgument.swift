//
//  Types+ExpressibleByArgument.swift
//  Falinks
//
//  Created by Lucka on 24/10/2024.
//

import ArgumentParser
import Foundation
import Generator
import SphereGeometry

extension Level : @retroactive ExpressibleByArgument {
}

extension Region.Code : ExpressibleByArgument {
}
