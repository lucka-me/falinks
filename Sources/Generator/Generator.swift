//
//  Generator.swift
//  Generator
//
//  Created by Lucka on 24/9/2024.
//

import Foundation
import OverpassKit
import SphereGeometry

public actor Generator {
    nonisolated let workingDirectory: URL
    
    let taskGroup: ConstrainedTaskGroup<Duration>
    
    var countries: [ Region ] = [ ]
    
    public init(workingDirectory: URL, maxTasks: Int) throws {
        let fileManager = FileManager.default
        
        try fileManager.ensureDirectory(at: workingDirectory)
        self.workingDirectory = workingDirectory
        
        self.taskGroup = .init(maxTasks: maxTasks)
        
        try fileManager.ensureDirectory(at: self.metadataSubdivisionsDirectory)
        try fileManager.ensureDirectory(at: self.geometryDirectory)
        try fileManager.ensureDirectory(at: self.coverCompressedDirectory)
        try fileManager.ensureDirectory(at: self.coverRawDirectory)
        try fileManager.ensureDirectory(at: self.indexDirectory)
        try fileManager.ensureDirectory(at: self.wikidataFlagsDirectory)
        try fileManager.ensureDirectory(at: self.wikidataRawDirectory)
    }
}

extension Generator {
    var flatRegions: [ Region ] {
        countries.flatMap { $0.subdivisions ?? [ $0 ] }
    }
}

fileprivate extension FileManager {
    func ensureDirectory(at url: URL) throws {
        if !fileExists(atPath: url.path(percentEncoded: false)) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
