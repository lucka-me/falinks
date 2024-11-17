//
//  ConvertBuilder.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

@resultBuilder
public enum ConvertBuilder {
    public static func buildBlock(_ components: String...) -> String {
        components.joined(separator: ",")
    }
    
    public static func buildExpression<Content: ConvertContent>(_ expression: Content) -> String {
        expression.conversion
    }
}
