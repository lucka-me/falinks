//
//  QueryContent.swift
//  OverpassKit
//
//  Created by Lucka on 24/9/2024.
//

import Foundation

public protocol QueryContent {
    var content: String { get }
}

public extension QueryContent {
    func `as`(_ name: String) -> some QueryContent {
        "\(content)->.\(name)"
    }
}

extension String : QueryContent {
    public var content: String {
        self
    }
}
