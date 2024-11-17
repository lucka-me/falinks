//
//  OutputElement.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 28/9/2024.
//

import Foundation

public protocol OutputElement : Decodable, Sendable {
    var id: UInt64 { get set }
}
