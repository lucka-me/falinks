//
//  Area.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation

public struct Area : QueryContent {
    public let content: String
    
    public init<Filter: FilterContent>(@FilterBuilder filterBy filters: () -> Filter) {
        self.content = "area\(filters().filtering)"
    }
}
