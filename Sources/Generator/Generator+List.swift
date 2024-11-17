//
//  Generator+List.swift
//  Falinks
//
//  Created by Lucka on 6/11/2024.
//

import Foundation

public extension Generator {
    func regions(matching predicate: (Region) -> Bool) -> [ Region ] {
        countries.flatMap { country in
            if let subdivisions = country.subdivisions {
                subdivisions.compactMap { predicate($0) ? $0 : nil }
            } else {
                predicate(country) ? [ country ] : [ ]
            }
        }
    }
}

