//
//  Elements.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 28/9/2024.
//

import Foundation

public struct Elements : QueryContent {
    public let content: String
    
    public init(set name: String) {
        self.content = ".\(name)"
    }
    
    public init(_ type: BasicType, in name: String) {
        self.content = "\(type.rawValue).\(name)"
    }
    
    public init<Filter: FilterContent>(_ type: BasicType, @FilterBuilder filterBy filters: () -> Filter) {
        self.content = "\(type.rawValue)\(filters().filtering)"
    }
    
    public init<Filter: FilterContent>(_ type: BasicType, in name: String, @FilterBuilder filterBy filters: () -> Filter) {
        self.content = "\(type.rawValue).\(name)\(filters().filtering)"
    }
}

public extension Elements {
    enum BasicType : String, Decodable, Sendable {
        case node
        case way
        case relation
    }
}
