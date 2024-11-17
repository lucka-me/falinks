//
//  ForEach.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

public struct ForEach : QueryContent {
    public let content: String
    
    public init<Body: QueryContent>(@QueryBuilder body: () -> Body) {
        self.content = "foreach { \(body().content) }"
    }
    
    public init<Body: QueryContent>(_ name: String, @QueryBuilder body: () -> Body) {
        self.content = "foreach.\(name) { \(body().content) }"
    }
}
