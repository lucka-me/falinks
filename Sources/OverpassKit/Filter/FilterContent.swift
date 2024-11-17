//
//  FilterContent.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

public protocol FilterContent {
    var filtering: String { get }
}

extension String : FilterContent {
    public var filtering: String {
        self
    }
}
