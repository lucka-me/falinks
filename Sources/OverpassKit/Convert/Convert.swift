//
//  Convert.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

public struct Convert : QueryContent {
    public let content: String
    
    public init<Convertion: ConvertContent>(typeName: String, @ConvertBuilder convertions: () -> Convertion) {
        self.content = "convert \(typeName) \(convertions().conversion)"
    }
}
