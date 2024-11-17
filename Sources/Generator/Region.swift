//
//  Region.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 24/9/2024.
//

import Foundation

public struct Region {
    public var id: UInt64
    public var code: Code

    public var wikidataIdentifier: String?
    
    public var subdivisions: [ Region ]? = nil
}

extension Region : Codable, Sendable {
    enum CodingKeys : CodingKey {
        case id
        case code
        case wikidataIdentifier
    }
}
