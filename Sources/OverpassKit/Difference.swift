//
//  Difference.swift
//  Falinks
//
//  Created by Lucka on 9/11/2024.
//

import Foundation

public struct Difference : QueryContent {
    public let content: String
    
    public init<Source: QueryContent, Subtract: QueryContent>(
        @QueryBuilder source: () -> Source, @QueryBuilder subtracting: () -> Subtract
    ) {
        self.content = "(\(source().content) - \(subtracting().content))"
    }
}
