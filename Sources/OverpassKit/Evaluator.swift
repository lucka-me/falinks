//
//  Evaluator.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

public struct Evaluator {
    public let evaluation: String
    
    private init(evaluation: String) {
        self.evaluation = evaluation
    }
}

public extension Evaluator {
    enum CountableType : String {
        case nodes
        case ways
        case relations
        case deriveds
        case basicElements = "nwr"
        case nodesAndWays = "nw"
        case waysAndRelations = "wr"
        case nodesAndRelations = "nr"
    }
    
    static func count(_ type: CountableType, in name: String) -> Self {
        .init(evaluation: "\(name).count(\(type.rawValue))")
    }
    
    static func tag(_ key: String) -> Self {
        .init(evaluation: "t[\"\(key)\"]")
    }
    
    static func id() -> Self {
        .init(evaluation: "id()")
    }
    
    func equals(_ value: String) -> Self {
        .init(evaluation: self.evaluation + "==\"\(value)\"")
    }
    
    func equals<Value: Numeric>(_ value: Value) -> Self {
        .init(evaluation: self.evaluation + "==\(value)")
    }
}
