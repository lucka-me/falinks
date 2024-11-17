//
//  Generator+Index.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 12/10/2024.
//

import Foundation
import SphereGeometry
import Turf

public extension Generator {
    func generateIndices() async throws {
        var (regionIndex, cellIndex) = try await withThrowingTaskGroup(
            of: (key: Region.Code, value: Region.Metadata).self
        ) { group in
            for country in countries {
                if country.subdivisions != nil {
                    group.addTask {
                        (country.code, try await self.generateIndexWithSubdivisions(for: country))
                    }
                } else {
                    group.addTask {
                        (country.code, try await self.generateIndexWithoutSubdivisions(for: country))
                    }
                }
            }
            
            var regionIndex: RegionIndex = [ : ]
            var cellIndex: CellIndex = [ : ]
            
            for try await metadata in group {
                regionIndex[metadata.key] = metadata.value
                if let subdivisions = metadata.value.subdivisions {
                    for subdivision in subdivisions {
                        for cell in subdivision.value.cells {
                            var codes = cellIndex[cell, default: .init()]
                            codes.insert(subdivision.key)
                            cellIndex.updateValue(codes, forKey: cell)
                        }
                    }
                } else {
                    for cell in metadata.value.cells {
                        var codes = cellIndex[cell, default: .init()]
                        codes.insert(metadata.key)
                        cellIndex.updateValue(codes, forKey: cell)
                    }
                }
            }
            
            return (regionIndex, cellIndex)
        }
        
        let fileManager = FileManager.default
        let regionIndexFile = regionIndexFileURL
        
        if fileManager.fileExists(atPath: regionIndexFile.path()) {
            regionIndex.merge(
                try JSONDecoder().decode(RegionIndex.self, from: try .init(contentsOf: regionIndexFile))
            ) { current, _ in
                current
            }
        }
        
        let cellIndexFile = cellIndexFileURL
        if fileManager.fileExists(atPath: cellIndexFile.path()) {
            cellIndex.merge(
                try JSONDecoder().decode(CellIndex.self, from: try .init(contentsOf: cellIndexFile))
            ) { current, new in
                current.union(new)
            }
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [ .prettyPrinted, .sortedKeys ]
        try encoder.encode(regionIndex).write(to: regionIndexFile)
        try encoder.encode(cellIndex).write(to: cellIndexFile)
    }
}

extension Generator {
    nonisolated var cellIndexFileURL: URL {
        indexDirectory
           .appending(component: "cells")
           .appendingPathExtension("json")
    }
    
    nonisolated var indexDirectory: URL {
        workingDirectory.appending(component: "index")
    }
    
    nonisolated var regionIndexFileURL: URL {
        indexDirectory
           .appending(component: "regions")
           .appendingPathExtension("json")
    }
}

fileprivate extension Generator {
    typealias CellIndex = [ CellIdentifier : Set<Region.Code> ]
    typealias RegionIndex = [ Region.Code : Region.Metadata ]
    
    static let alignedLevel = Level.at.5
    
    func generateIndexWithSubdivisions(for region: Region) throws -> Region.Metadata {
        var area = 0.0
        var subdivisions: [ Region.Code : Region.Metadata ] = [ : ]
        for subdivision in region.subdivisions! {
            let data = try generateIndexWithoutSubdivisions(for: subdivision)
            area += data.area
            subdivisions[subdivision.code] = data
        }
        
        return .init(
            area: area,
            boundingBox: .init(
                from: subdivisions.flatMap {
                    [ $0.value.boundingBox.southWest, $0.value.boundingBox.northEast ]
                }
            )!,
            subdivisions: subdivisions,
            cells: [ ]
        )
    }
    
    func generateIndexWithoutSubdivisions(for region: Region) throws -> Region.Metadata {
        let cells = CellCollection.guaranteed(
            cells: try Data(contentsOf: rawCellFileURL(of: region.code))
                .withUnsafeBytes { .init($0.bindMemory(to: CellIdentifier.self)) }
        )
        return .init(
            area: cells.reduce(into: 0.0) { $0 += $1.cell.area },
            boundingBox: .init(
                from: try JSONDecoder()
                    .decode(
                        MultiPolygon.self,
                        from: try .init(contentsOf: geometryFileURL(of: region.code))
                    )
                    .coordinates.flatMap { $0.flatMap { $0 } }
            )!,
            subdivisions: nil,
            cells: cells.aligned(at: Self.alignedLevel)
        )
    }
}

fileprivate extension Region {
    struct Metadata {
        var area: Double
        var boundingBox: BoundingBox
        
        var subdivisions: [ Region.Code : Metadata ]?
        
        var cells: Set<CellIdentifier> = [ ]
    }
}

extension Region.Metadata : Codable {
    enum CodingKeys : CodingKey {
        case area
        case boundingBox
        case subdivisions
    }
}
