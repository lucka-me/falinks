//
//  ConvertContent.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

public protocol ConvertContent {
    var conversion: String { get }
}

extension String : ConvertContent {
    public var conversion: String {
        self
    }
}
