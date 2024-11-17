// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Generator
import OverpassKit
import SphereGeometry

@main
struct FalinksCommand : AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: [
            AllCommand.self,
            MetadataCommand.self,
            GeometryCommand.self,
            CoverCommand.self,
            IndexCommand.self,
            WikidataCommand.self,
            
            ListCommand.self
        ],
        defaultSubcommand: AllCommand.self
    )
}
