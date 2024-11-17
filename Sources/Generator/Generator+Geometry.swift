//
//  Generator+Boundary.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 25/9/2024.
//

import Foundation
import OverpassKit
import Turf

public extension Generator {
    struct Omit: Sendable {
        public enum Coastline: String, CaseIterable, Sendable {
            case all
            case open
        }
        
        public let coastlines: Coastline?
        public let segments: Set<UInt64>
        public let unownedInners: Bool
        
        public init(coastlines: Coastline?, segments: Set<UInt64>, unownedInners: Bool) {
            self.coastlines = coastlines
            self.segments = segments
            self.unownedInners = unownedInners
        }
    }
    
    func ensureGeometries(
        with api: Overpass,
        cooldown: Duration,
        omitting: Omit
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for region in self.flatRegions {
                group.addTask {
                    try await self.ensureGeometry(
                        of: region,
                        with: api,
                        cooldown: cooldown,
                        omitting: omitting
                    )
                }
            }
            try await group.waitForAll()
        }
    }
    
    nonisolated func geometryFileURL(of region: Region.Code) -> URL {
        geometryDirectory
            .appending(component: region.rawValue)
            .appendingPathExtension("json")
    }
}

extension Generator {
    nonisolated var geometryDirectory: URL {
        workingDirectory.appending(component: "geometry")
    }
}

fileprivate extension Generator {
    enum GeometryError : Error {
        case unpairedNodeExists(id: UInt64, region: Region.Code, nodes: [ UInt64 ])
        case openSegmentsExists(id: UInt64, region: Region.Code, segmentId: UInt64, nodeId: UInt64)
        case unownedInnerRing(id: UInt64, region: Region.Code, rings: [ Ring ])
    }
    
    func ensureGeometry(
        of region: Region, with api: Overpass, cooldown: Duration, omitting: Omit
    ) async throws {
        let file = geometryFileURL(of: region.code)
        guard !FileManager.default.fileExists(atPath: file.path()) else {
            return
        }
        
        let geometry: MultiPolygon
        
        if region.code == .country(code: "AQ") {
            geometry = try await fetchAntarcticGeometry(of: region, with: api, cooldown: cooldown)
        } else {
            geometry = try await fetchRegularGeometry(of: region, with: api, cooldown: cooldown, omitting: omitting)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [ .prettyPrinted, .sortedKeys, .withoutEscapingSlashes ]
        try encoder.encode(geometry).write(to: file)
    }
    
    func fetchAntarcticGeometry(
        of region: Region, with api: Overpass, cooldown: Duration
    ) async throws -> MultiPolygon {
        var table = GeometryTable()
        
        /*
         [out:json];
         relation(<region.id>)->.region;
         (
           way["natural"="coastline"](-90,-180,-60,180);
           -
           way(r.region)["natural"="coastline"]->.boundaries;
         )->.geometries;
         .geometries out geom;
         */
        try await taskGroup.addTask {
            try await api.query(GeometryElement.self) {
                Elements(.relation) {
                    FilterBy(id: region.id)
                }
                .as("region")
                
                Difference {
                    Elements(.way) {
                        FilterBy(tag: "natural", equals: "coastline")
                        FilterBy(south: -90, west: -180, north: -60, east: 180)
                    }
                } subtracting: {
                    Elements(.way) {
                        Recurse(into: .relations, of: "region")
                        FilterBy(tag: "natural", equals: "coastline")
                    }
                }
                .as("geometries")
                
                Output(name: "geometries", geolocation: .geometry)
            }
        }.forEach { element in
            guard
                element.nodes.count == element.geometry.count,
                element.nodes.count > 1
            else {
                return
            }

            if element.nodes.first != element.nodes.last {
                table.insert(element: element)
            } else {
                let ring = Ring(coordinates: element.geometry.map { $0.coordinate })
                if table.inners.contains(element.id) {
                    table.innerRings.append(ring)
                } else {
                    table.outerRings.append(ring)
                }
            }
        }
        
        // Find the two nodes on Antimeridian and create a virtual segment to connect them
        if let firstSegment = table.segments.first {
            var westNode = (firstSegment.value.endpointNodes.start, firstSegment.value.line.first!)
            var eastNode = westNode
            
            for segment in table.segments {
                if let start = segment.value.line.first {
                    if start.longitude < westNode.1.longitude {
                        westNode.0 = segment.value.endpointNodes.start
                        westNode.1 = start
                    } else if start.longitude > eastNode.1.longitude {
                        eastNode.0 = segment.value.endpointNodes.start
                        eastNode.1 = start
                    }
                }
                if let end = segment.value.line.last {
                    if end.longitude < westNode.1.longitude {
                        westNode.0 = segment.value.endpointNodes.end
                        westNode.1 = end
                    } else if end.longitude > eastNode.1.longitude {
                        eastNode.0 = segment.value.endpointNodes.end
                        eastNode.1 = end
                    }
                }
            }
            
            table.segments[0] = .init(
                id: 0,
                role: .outer,
                endpointNodes: (westNode.0, eastNode.0),
                line: [
                    westNode.1,
                    .init(latitude: -90, longitude: -180),
                    .init(latitude: -90, longitude:  180),
                    eastNode.1
                ]
            )
            table.insert(node: westNode.0, of: 0)
            table.insert(node: eastNode.0, of: 0)
        }
        
        // Detect unpaired nodes (value.count != 2)
        let unpairedNodes = table.endpoints.compactMap { $0.value.count == 2 ? nil : $0.0 }
        guard unpairedNodes.isEmpty else {
            throw GeometryError.unpairedNodeExists(
                id: region.id, region: region.code, nodes: unpairedNodes
            )
        }
        
        var queue = Array<UInt64>(table.segments.keys)
        
        // Concatenate the boundaries following node id
        while let segmentId = queue.popLast() {
            guard let segment = table.concatenate(from: segmentId) else {
                // Already concatenated
                continue
            }
            
            let ring = Ring(coordinates: segment.line)
            switch segment.role {
            case .inner:
                table.innerRings.append(ring)
            case .outer:
                table.outerRings.append(ring)
            }
        }
        
        let outerPolygons = table.buildPolygons()
        
        return .init(outerPolygons)
    }
    
    func fetchRegularGeometry(
        of region: Region, with api: Overpass, cooldown: Duration, omitting: Omit
    ) async throws -> MultiPolygon {
        var table = GeometryTable()
        
        /* Query roles and record the inners */
        /*
         [out:json];
         relation(region.id);
         out skel;
         */
        try await taskGroup.addTask {
            try await api.query(RelationElement.self) {
                Elements(.relation) {
                    FilterBy(id: region.id)
                }
                Output(verbosity: .skleton)
            }
        }.forEach { element in
            for member in element.members where member.type == .way && member.role == "inner" {
                table.inners.insert(member.ref)
            }
        }
        
        /* Query geometries */
        /*
        [out:json];
        relation(<region.id>)->.region;
        area["ISO3166-1/2"=<region.code>]["boundary"!="historic"]->.region_area;
        way(r.region)->.boundaries;
        (
            way.boundaries["maritime"!="yes"];
            way.boundaries["natural"="coastline"];
            way(area.region_area)["natural"="coastline"];
        )->.geometries;
        .geometries out geom;
         */
        try await taskGroup.addTask(cooldown: cooldown) {
            let queryCoastlines = omitting.coastlines != .all
            return try await api.query(GeometryElement.self) {
                Elements(.relation) {
                    FilterBy(id: region.id)
                }
                .as("region")
                
                if queryCoastlines {
                    Area {
                        FilterBy(tag: region.code.standard, equals: region.code.rawValue)
                        FilterBy(tag: "boundary", notEquals: "historic")
                    }
                    .as("region_area")
                }
                
                Elements(.way) {
                    Recurse(into: .relations, of: "region")
                }
                .as("boundaries")
                
                Union {
                    Elements(.way, in: "boundaries") {
                        FilterBy(tag: "maritime", notEquals: "yes")
                    }
                    Elements(.way, in: "boundaries") {
                        FilterBy(tag: "natural", equals: "coastline")
                    }
                    
                    if queryCoastlines {
                        Elements(.way) {
                            FilterBy(area: "region_area")
                            FilterBy(tag: "natural", equals: "coastline")
                        }
                    }
                }
                .as("geometries")
                
                Output(name: "geometries", geolocation: .geometry)
            }
        }.forEach { element in
            guard
                !omitting.segments.contains(element.id),
                element.nodes.count == element.geometry.count,
                element.nodes.count > 1
            else {
                return
            }

            if element.nodes.first != element.nodes.last {
                table.insert(element: element)
            } else {
                let ring = Ring(coordinates: element.geometry.map { $0.coordinate })
                if table.inners.contains(element.id) {
                    table.innerRings.append(ring)
                } else {
                    table.outerRings.append(ring)
                }
            }
        }
        
        if omitting.coastlines == .open, !table.coastlines.isEmpty {
            var modified: Bool
            repeat {
                modified = false
                table.coastlines = table.coastlines.filter { segmentId in
                    let segment = table.segments[segmentId]!
                    var startNode = table.endpoints[segment.endpointNodes.start]!
                    var endNode = table.endpoints[segment.endpointNodes.end]!
                    
                    guard startNode.count == 1 || endNode.count == 1 else {
                        return true
                    }
                    
                    table.segments.removeValue(forKey: segment.id)
                    startNode.remove(segmentId)
                    endNode.remove(segmentId)
                    
                    if startNode.isEmpty {
                        table.endpoints.removeValue(forKey: segment.endpointNodes.start)
                    } else {
                        table.endpoints.updateValue(startNode, forKey: segment.endpointNodes.start)
                    }
                    
                    if endNode.isEmpty {
                        table.endpoints.removeValue(forKey: segment.endpointNodes.end)
                    } else {
                        table.endpoints.updateValue(endNode, forKey: segment.endpointNodes.end)
                    }
                    
                    modified = true
                    
                    return false
                }
            } while modified
        }
        
        // Detect unpaired nodes (value.count != 2)
        let unpairedNodes = table.endpoints.compactMap { $0.value.count == 2 ? nil : $0.0 }
        guard unpairedNodes.isEmpty else {
            throw GeometryError.unpairedNodeExists(
                id: region.id, region: region.code, nodes: unpairedNodes
            )
        }
        
        // Now, all segments should be closed
        
        // Make an ordered queue, coastline < inner < outer
        // Notic it's pop from last, not first, so the order is "reversed"
        var queue = table.segments.keys.sorted { lhs, rhs in
            let lhsIsCoastline = table.coastlines.contains(lhs)
            let rhsIsCoastline = table.coastlines.contains(rhs)
            guard lhsIsCoastline == rhsIsCoastline else {
                return lhsIsCoastline
            }
            
            let lhsIsInner = table.inners.contains(lhs)
            let rhsIsInner = table.inners.contains(rhs)
            guard lhsIsInner == rhsIsInner else {
                return lhsIsInner
            }
            
            return lhs < rhs
        }
        
        // Concatenate the boundaries following node id
        while let segmentId = queue.popLast() {
            guard let segment = table.concatenate(from: segmentId) else {
                // Already concatenated
                continue
            }
            
            let ring = Ring(coordinates: segment.line)
            switch segment.role {
            case .inner:
                table.innerRings.append(ring)
            case .outer:
                table.outerRings.append(ring)
            }
        }
        
        let outerPolygons = table.buildPolygons()
        
        guard omitting.unownedInners || table.innerRings.isEmpty else {
            throw GeometryError.unownedInnerRing(id: region.id, region: region.code, rings: table.innerRings)
        }
        
        return .init(outerPolygons)
    }
}

fileprivate struct GeometryElement : OutputTagsElement, OutputGeometryElement {
    struct TagsContent: Decodable, Sendable {
        var natural: String?
    }
    typealias Tags = Optional<TagsContent>

    var id: UInt64
    
    var nodes: [ UInt64 ]
    var geometry: [ LatLng ]

    var tags: Tags
    
    var isCoastline: Bool {
        tags?.natural == "coastline"
    }
}

fileprivate struct GeometryTable {
    var segments: [ UInt64 : Segment ] = [ : ]
    
    var endpoints: [ UInt64 : Set<UInt64> ] = [ : ]
    
    var inners: Set<UInt64> = [ ]
    var coastlines: Set<UInt64> = [ ]
    
    var outerRings: [ Ring ] = [ ]
    var innerRings: [ Ring ] = [ ]
}

fileprivate struct RelationElement : OutputRelationSkletonElement {
    var id: UInt64
    var members: [ OutputElementMember ]
}

fileprivate struct Segment {
    enum Role {
        case inner
        case outer
    }

    let id: UInt64
    let role: Role
    
    var endpointNodes: (start: UInt64, end: UInt64)
    var line: [ LocationCoordinate2D ]
}

fileprivate extension GeometryTable {
    mutating func buildPolygons() -> [ Polygon ] {
        outerRings.map { outerRing in
            guard !innerRings.isEmpty else {
                return Polygon(outerRing: outerRing)
            }
            
            var containedInnerRings: [ Ring ] = [ ]
            innerRings.removeAll { innerRing in
                let contained = innerRing.coordinates.contains { outerRing.contains($0) }
                if contained {
                    containedInnerRings.append(innerRing)
                }
                return contained
            }
            
            return Polygon(outerRing: outerRing, innerRings: containedInnerRings)
        }
    }
    
    mutating func concatenate(from segmentId: UInt64) -> Segment? {
        guard var segment = segments.removeValue(forKey: segmentId) else {
            // Already concatenated
            return nil
        }
        var lastSegmentId = segment.id
        repeat {
            guard
                let nextSegmentId = popCandidate(for: lastSegmentId, at: segment.endpointNodes.end),
                let nextSegment = segments.removeValue(forKey: nextSegmentId)
            else {
                // The segment is open
                break
            }
            
            if segment.endpointNodes.end == nextSegment.endpointNodes.start {
                segment.line.append(contentsOf: nextSegment.line[ 1 ..< nextSegment.line.endIndex ])
                segment.endpointNodes.end = nextSegment.endpointNodes.end
            } else {
                segment.line.append(
                    contentsOf: nextSegment.line[ 0 ..< (nextSegment.line.endIndex - 1) ].reversed()
                )
                segment.endpointNodes.end = nextSegment.endpointNodes.start
            }
            lastSegmentId = nextSegmentId
            
        } while !segment.closed
        
        return segment
    }
    
    mutating func insert(element: GeometryElement) {
        let segment = Segment(element, isInner: inners.contains(element.id))
        segments[segment.id] = segment
        insert(node: segment.endpointNodes.start, of: segment.id)
        insert(node: segment.endpointNodes.end, of: segment.id)
        if element.isCoastline {
            coastlines.insert(segment.id)
        }
    }
    
    mutating func insert(node: UInt64, of element: UInt64) {
        var elements = endpoints[node, default: .init()]
        elements.insert(element)
        endpoints.updateValue(elements, forKey: node)
    }
    
    private mutating func popCandidate(for segment: UInt64, at node: UInt64) -> UInt64? {
        guard var segmentPair = endpoints.removeValue(forKey: node) else {
            return nil
        }
        segmentPair.remove(segment)
        return segmentPair.first // Should never be nil, never mind
    }
}

fileprivate extension LatLng {
    var coordinate: LocationCoordinate2D {
        .init(latitude: lat, longitude: lon)
    }
}

fileprivate extension Segment {
    init(_ element: GeometryElement, isInner: Bool) {
        self.id = element.id
        self.endpointNodes = (element.nodes.first!, element.nodes.last!)
        self.line = element.geometry.map { $0.coordinate }
        self.role = isInner ? .inner : .outer
    }
    
    var closed: Bool {
        endpointNodes.start == endpointNodes.end
    }

    var lineString: LineString {
        .init(line)
    }
}
