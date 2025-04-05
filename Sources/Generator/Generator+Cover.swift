//
//  Generator+Cover.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 30/9/2024.
//

import Compression
import Foundation
import SphereCoverer
import SphereGeometry
import Turf

public extension Generator {
    func ensureCovers(at level: Level, compress: Bool) async throws {
        let coverer = Coverer(levelRange: .min ... level, mode: .balanced)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for region in self.flatRegions {
                group.addTask {
                    try await self.ensureCover(of: region, with: coverer, compress: compress)
                }
            }
            try await group.waitForAll()
        }
    }
    
    nonisolated func rawCellFileURL(of region: Region.Code) -> URL {
        coverRawDirectory
            .appending(component: region.rawValue)
            .appendingPathExtension("cells")
    }
}

extension Generator {
    nonisolated var coverDirectory: URL {
        workingDirectory.appending(component: "cover")
    }
    
    nonisolated var coverCompressedDirectory: URL {
        coverDirectory.appending(component: "compressed")
    }
    
    nonisolated var coverRawDirectory: URL {
        coverDirectory.appending(component: "raw")
    }
    
    nonisolated func compressedCellFileURL(of region: Region.Code) -> URL {
        coverCompressedDirectory
            .appending(component: region.rawValue)
            .appendingPathExtension("cells-lzfse")
    }
}

fileprivate extension Generator {
    func ensureCover(of region: Region, with coverer: Coverer, compress: Bool) async throws {
        let fileManager = FileManager.default
        let rawFile = rawCellFileURL(of: region.code)
        let compressedFile = compressedCellFileURL(of: region.code)
        
        let collectionData: Data
        if !fileManager.fileExists(atPath: rawFile.path(percentEncoded: false)) {
            let geometry = try JSONDecoder()
                .decode(
                    MultiPolygon.self,
                    from: try .init(contentsOf: geometryFileURL(of: region.code))
                )
            let collection = await taskGroup.addTask {
                let startTime = SuspendingClock.now
                let result = geometry.polygons.reduce(into: CellCollection()) {
                    $0.formUnion(coverer.cover($1))
                }
                print(
                    "[\(region.code.rawValue)] " +
                    "Generated \(result.count) cells in \(SuspendingClock.now - startTime)"
                )
                return result
            }
            collectionData = collection.cells.withUnsafeBufferPointer { Data(buffer: $0) }
            try collectionData.write(to: rawFile)
            
            try? JSONEncoder()
                .encode(
                    MultiPolygon(
                        collection.map { cellIdentifier in
                            .init(outerRing: .init(coordinates: cellIdentifier.cell.plottableLocationCoordinateShape))
                        }
                    )
                )
                .write(
                    to: self.coverDirectory
                        .appending(component: region.code.rawValue)
                        .appendingPathExtension("json")
                )
            
        } else if compress, !fileManager.fileExists(atPath: compressedFile.path(percentEncoded: false)) {
            collectionData = try .init(contentsOf: rawFile)
        } else {
            return
        }
        
        fileManager.createFile(atPath: compressedFile.path(percentEncoded: false), contents: nil)
        let compressedFileHandle = try FileHandle(forWritingTo: compressedFile)
        let outputFilter = try OutputFilter(.compress, using: .lzfse) { segment in
            if let segment {
                try compressedFileHandle.write(contentsOf: segment)
            }
        }
        try outputFilter.write(collectionData)
        try outputFilter.finalize()
    }
}
