//
//  OutputTagsElement.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

public protocol OutputTagsElement : OutputElement {
    associatedtype Tags: Decodable & Sendable
    
    var tags: Tags { get set }
}
