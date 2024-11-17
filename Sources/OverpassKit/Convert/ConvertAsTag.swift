//
//  ConvertAsTag.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

public struct ConvertAsTag : ConvertContent {
    public let conversion: String
    
    public init(_ key: String, by evaluator: Evaluator = .id()) {
        self.conversion = "\(key) = \(evaluator.evaluation)"
    }
}
