//
//  ConvertAsId.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

public struct ConvertAsId : ConvertContent {
    public let conversion: String
    
    public init(by evaluator: Evaluator = .id()) {
        self.conversion = "::id = \(evaluator.evaluation)"
    }
}
