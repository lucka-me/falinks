//
//  OutputRelationSkletonElement.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 28/9/2024.
//

import Foundation

public protocol OutputRelationSkletonElement : OutputElement {
    var members: [ OutputElementMember ] { get set }
}

public struct OutputElementMember : Decodable, Sendable {
    public var type: Elements.BasicType
    public var ref: UInt64
    public var role: String
}
