//
//  Output.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

public struct Output : QueryContent {
    public let content: String
    
    public init(verbosity: Verbosity = .body, geolocation: GeolocationModifier? = nil) {
        content = "out \(verbosity.rawValue) \(geolocation?.rawValue ?? "")"
    }
    
    public init(name: String, verbosity: Verbosity = .body, geolocation: GeolocationModifier? = nil) {
        content = ".\(name) out \(verbosity.rawValue) \(geolocation?.rawValue ?? "")"
    }
}

public extension Output {
    enum Verbosity: String {
        case skleton = "skel"
        case body = ""
        case tags
    }
    
    enum GeolocationModifier: String {
        case geometry = "geom"
    }
}
