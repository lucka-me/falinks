//
//  Optionally.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 11/10/2024.
//

import Foundation

public struct Optionally : QueryContent {
    public let content: String
    
    public init<Body: QueryContent>(_ evaluator: Evaluator, @QueryBuilder body: () -> Body) {
        self.content = "if(\(evaluator.evaluation)) { \(body().content) }"
    }
}
