//
//  Overpass.swift
//  OverpassKit
//
//  Created by Lucka on 24/9/2024.
//

import Foundation

public actor Overpass {
    private let api: URL
    
    public init(api: URL = Overpass.defaultAPI) {
        self.api = api
    }
}

public extension Overpass {
    static let defaultAPI = URL(string: "https://overpass-api.de/api/interpreter")!
    
    @inlinable func query<Element: Decodable, Content: QueryContent>(
        _ type: Element.Type, @QueryBuilder query: @escaping () -> Content
    ) async throws -> [ Element ] {
        return try await self.query(query: query)
    }
    
    func query<Element: Decodable, Content: QueryContent>(
        @QueryBuilder query: @escaping () -> Content
    ) async throws -> [ Element ] {
        let url = api.appending(
            queryItems: [
                .init(
                    name: "data",
                    value: "[out:json]; \(query().content)"
                )
            ]
        )
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(OverpassOutput<Element>.self, from: data).elements
    }
}

fileprivate struct OverpassOutput<Element: Decodable> : Decodable {
    var elements: [ Element ]
}
