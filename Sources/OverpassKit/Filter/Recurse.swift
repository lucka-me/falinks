//
//  Recurse.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

public struct Recurse : FilterContent {
    public let filtering: String
    
    public init(into target: Target) {
        self.filtering = "(\(target.rawValue))"
    }
    
    public init(into target: Target, by role: String) {
        self.filtering = "(\(target.rawValue):\"\(role)\")"
    }
    
    public init(into target: Target, of name: String) {
        self.filtering = "(\(target.rawValue).\(name))"
    }
    
    public init(into target: Target, of name: String, by role: String) {
        self.filtering = "(\(target.rawValue).\(name):\"\(role)\")"
    }
}

public extension Recurse {
    enum Target : String {
        case relations = "r"
    }
}
