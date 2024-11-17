//
//  Turf+CellAlgebra.swift
//  SphereGeometry
//
//  Created by Lucka on 1/10/2024.
//

import simd
import SphereGeometry
import Turf

extension MultiPolygon : CellAlgebra {
    public func relation(with cell: Cell) -> CellRelation {
        // TODO: Check for empty
        let vertices = cell.vertices
        let containedVertexCount = vertices.count { contains($0.locationCoordinate) }
        switch containedVertexCount {
        case 0:
            if intersectsWhenVerticesAreAllDisjoint(cell: cell, vertices: vertices) {
                return .intersect
            } else {
                return .disjoint
            }
        case 4:
            if intersectsWhenVerticesAreAllContained(cell: cell, vertices: vertices) {
                return .intersect
            } else {
                return .contain
            }
        default:
            return .intersect
        }
    }
}

extension Polygon : CellAlgebra {
    public func relation(with cell: Cell) -> CellRelation {
        // TODO: Check for empty
        let vertices = cell.vertices
        let containedVertexCount = vertices.count { contains($0.locationCoordinate) }
        switch containedVertexCount {
        case 0:
            if intersectsWhenVerticesAreAllDisjoint(
                cell: cell, diagonals: PrecalculatedLineSegment.diagonals(of: vertices)
            ) {
                return .intersect
            } else {
                return .disjoint
            }
        case 4:
            if intersectsWhenVerticesAreAllContained(
                cell: cell, diagonals: PrecalculatedLineSegment.diagonals(of: vertices)
            ) {
                return .intersect
            } else {
                return .contain
            }
        default:
            return .intersect
        }
    }
}

fileprivate struct PrecalculatedPoint {
    let cell: Cell
    let coordinate: CartesianCoordinate.RawValue
    
    init(_ locationCoordinate: LocationCoordinate2D) {
        let cartesianCoordinate = locationCoordinate.cartesianCoordinate
        self.coordinate = cartesianCoordinate.rawValue
        self.cell = cartesianCoordinate.leafCell
    }
}

fileprivate struct PrecalculatedLineSegment {
    typealias RawValue = CartesianCoordinate.RawValue
    
    static func diagonals(of vertices: [ LeafCoordinate ]) -> [ Self ] {
        [
            .init(
                a: vertices[0].cartesianCoordinate.rawValue,
                b: vertices[2].cartesianCoordinate.rawValue
            ),
            .init(
                a: vertices[1].cartesianCoordinate.rawValue,
                b: vertices[3].cartesianCoordinate.rawValue
            )
        ]
    }
    
    let a: RawValue
    let b: RawValue
    
    let crossValue: RawValue
    
    init(a: RawValue, b: RawValue) {
        self.a = a
        self.b = b
        self.crossValue = cross(a, b)
    }
}

fileprivate extension MultiPolygon {
    func intersectsWhenVerticesAreAllDisjoint(cell: Cell, vertices: [ LeafCoordinate ]) -> Bool {
        let diagonals = PrecalculatedLineSegment.diagonals(of: vertices)
        return self.polygons.contains { polygon in
            polygon.intersectsWhenVerticesAreAllDisjoint(cell: cell, diagonals: diagonals)
        }
    }
    
    func intersectsWhenVerticesAreAllContained(cell: Cell, vertices: [ LeafCoordinate ]) -> Bool {
        let diagonals = PrecalculatedLineSegment.diagonals(of: vertices)
        return self.polygons.contains { polygon in
            polygon.intersectsWhenVerticesAreAllContained(cell: cell, diagonals: diagonals)
        }
    }
}

fileprivate extension Polygon {
    func intersectsWhenVerticesAreAllDisjoint(cell: Cell, diagonals: [ PrecalculatedLineSegment ]) -> Bool {
        
        
        var lastPoint = PrecalculatedPoint(self.outerRing.coordinates.first!)
        guard !cell.intersects(lastPoint.cell) else {
            return true
        }
        return self.outerRing.coordinates.suffix(from: 1).contains { coordinate in
            let point = PrecalculatedPoint(coordinate)
            defer {
                lastPoint = point
            }
            return cell.intersects(
                (lastPoint, point), precalculatedDiagonals: diagonals
            )
        }
    }
    
    func intersectsWhenVerticesAreAllContained(cell: Cell, diagonals: [ PrecalculatedLineSegment ]) -> Bool {
        self.coordinates.contains { ring in
            var lastPoint = PrecalculatedPoint(ring.first!)
            guard !cell.intersects(lastPoint.cell) else {
                return true
            }
            return ring.suffix(from: 1).contains { coordinate in
                let point = PrecalculatedPoint(coordinate)
                defer {
                    lastPoint = point
                }
                return cell.intersects(
                    (lastPoint, point), precalculatedDiagonals: diagonals
                )
            }
        }
    }
}

fileprivate extension Cell {
    func intersects(
        _ segment: (a: PrecalculatedPoint, b: PrecalculatedPoint),
        precalculatedDiagonals: [ PrecalculatedLineSegment ]
    ) -> Bool {
        guard !intersects(segment.b.cell) else {
            return true
        }
        
        if self.coordinate.zone == segment.a.cell.zone, self.coordinate.zone == segment.b.cell.zone {
            if segment.a.cell.coordinate.i < self.coordinate.i && segment.b.cell.coordinate.i < self.coordinate.i {
                return false
            }
            if segment.a.cell.coordinate.j < self.coordinate.j && segment.b.cell.coordinate.j < self.coordinate.j {
                return false
            }
            
            let step = LeafCoordinate.step(at: self.level)
            if segment.a.cell.coordinate.i > self.coordinate.i + step && segment.b.cell.coordinate.i > self.coordinate.i + step {
                return false
            }
            if segment.a.cell.coordinate.j > self.coordinate.j + step && segment.b.cell.coordinate.j > self.coordinate.j + step {
                return false
            }
            
            var range = self.coordinate.i ... self.coordinate.i + step
            if range.contains(segment.a.cell.coordinate.i) && range.contains(segment.b.cell.coordinate.i) {
                return true
            }
            range = self.coordinate.j ... self.coordinate.j + step
            if range.contains(segment.a.cell.coordinate.j) && range.contains(segment.b.cell.coordinate.j) {
                return true
            }
        }
        
        return precalculatedDiagonals.contains { diagonal in
            let segmentCross = cross(segment.a.coordinate, segment.b.coordinate)
            var intersection = cross(diagonal.crossValue, segmentCross)
            
            if dot(intersection, segment.a.coordinate) < 0 && dot(intersection, segment.b.coordinate) < 0 {
                intersection = -intersection
            }
            
            return intersection.between(segment.a.coordinate, segment.b.coordinate, segmentCross)
                && intersection.between(diagonal.a, diagonal.b, diagonal.crossValue)
        }
    }
}

fileprivate extension SIMD3 where Scalar == Double {
    func between(_ a: Self, _ b: Self, _ abCross: Self) -> Bool {
        guard dot(self, a) >= 0 || dot(self, b) >= 0 else {
            return false
        }
        return dot(cross(a, self), cross(b, self)) < 0
    }
}
