//
//  FilterBuilder.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

@resultBuilder
public enum FilterBuilder {
    public static func buildBlock(_ components: String...) -> String {
        components.joined()
    }
    
    public static func buildExpression<Content: FilterContent>(_ expression: Content) -> String {
        expression.filtering
    }
}

