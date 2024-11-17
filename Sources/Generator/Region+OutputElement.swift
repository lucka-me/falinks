//
//  Region+OutputElement.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 30/9/2024.
//

import OverpassKit

extension Region {
    struct Element : OutputTagsElement {
        struct Tags : Decodable {
            var code: Code
            var wikidata: String
        }
        
        var id: UInt64
        var tags: Tags
    }
    
    init(element: Element) {
        self.init(
            id: element.id,
            code: element.tags.code,
            wikidataIdentifier: element.tags.wikidata.isEmpty ? nil : element.tags.wikidata
        )
    }
}

