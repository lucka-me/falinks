//
//  OutputGeometryElement.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 27/9/2024.
//

import Foundation

public protocol OutputGeometryElement : OutputElement {
    var geometry: [ LatLng ] { get set }
    var nodes: [ UInt64 ] { get set }
}

public struct LatLng : Decodable, Sendable {
    public var lat: Double
    public var lon: Double
}
