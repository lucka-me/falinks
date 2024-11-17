//
//  Union.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

public struct Union : QueryContent {
    public let content: String
    
    public init<Content: QueryContent>(@QueryBuilder content: () -> Content) {
        self.content = "(\(content().content))"
    }
}
