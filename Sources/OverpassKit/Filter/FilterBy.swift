//
//  FilterBy.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

public struct FilterBy : FilterContent {
    public var filtering: String
    
    public init(area name: String) {
        self.filtering = "(area.\(name))"
    }
    
    public init(id: UInt64) {
        self.filtering = "(\(id))"
    }
    
    public init(tag name: String, equals value: String) {
        self.filtering = "[\"\(name)\"=\"\(value)\"]"
    }
    
    public init(tag name: String, exists: Bool) {
        self.filtering = "[\(exists ? "" : "!")\"\(name)\"]"
    }
    
    public init(tag name: String, notEquals value: String) {
        self.filtering = "[\"\(name)\"!=\"\(value)\"]"
    }
    
    public init(south: Double, west: Double, north: Double, east: Double) {
        self.filtering = "(\(south),\(west),\(north),\(east))"
    }
}
