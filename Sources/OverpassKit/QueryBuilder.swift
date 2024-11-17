//
//  QueryBuilder.swift
//  OverpassKit
//
//  Created by Lucka on 24/9/2024.
//

import Foundation

@resultBuilder
public enum QueryBuilder {
    public static func buildBlock(_ components: String...) -> String {
        components.joined()
    }
    
    public static func buildOptional(_ component: String?) -> String {
        component ?? ""
    }
    
    public static func buildExpression<Content: QueryContent>(_ expression: Content) -> String {
        "\(expression.content);"
    }
}
