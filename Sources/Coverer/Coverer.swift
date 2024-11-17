//
//  Coverer.swift
//  SphereGeometry
//
//  Created by Lucka on 1/10/2024.
//

import SphereGeometry

public struct Coverer {
    private let levelRange: ClosedRange<Level>
    private let mode: Mode
    
    public init(
        levelRange: ClosedRange<Level>,
        mode: Mode = .exterior
    ) {
        self.levelRange = levelRange
        self.mode = mode
    }
}

public extension Coverer {
    enum Mode : Sendable {
        case exterior
        case balanced
    }
    
    @inlinable func cover(_ geometry: CellAlgebra) -> CellCollection {
        self.cover(geometry, with: .wholeSpere)
    }
    
    func cover(_ geometry: CellAlgebra, with initialCandidates: CellCollection) -> CellCollection {
        var queue: Queue = [ ]
        var result: Set<CellIdentifier> = [ ]
        for candidate in initialCandidates {
            let cell = candidate.cell
            switch geometry.relation(with: cell) {
            case .intersect:
                let candidate = Candidate(cell: cell, for: geometry)
                queue.enqueu(candidate)
            case .contain:
                result.insert(candidate)
            default:
                break
            }
        }
        
        while let candidate = queue.popFirst() {
            guard candidate.cell.level < levelRange.upperBound else {
                if mode == .exterior || candidate.coveringMoreThanHalf {
                    result.insert(candidate.identifier)
                }
                continue
            }
            for child in candidate.containedChildren {
                result.insert(child.identifier)
            }
            for child in candidate.intersectedChildren {
                let candidate = Candidate(cell: child, for: geometry)
                queue.enqueu(candidate)
            }
        }
        
        return .init(result)
    }
}

extension Coverer : Sendable {
    
}

fileprivate extension Coverer {
    typealias Queue = [ Candidate ]
}

fileprivate extension Coverer.Queue {
    mutating func popFirst() -> Element? {
        isEmpty ? nil : removeFirst()
    }
    
    mutating func enqueu(_ element: Element) {
        var first = startIndex
        var count = distance(from: first, to: endIndex)
        while count > 0 {
            let step = count / 2
            let it = index(first, offsetBy: step)
            
            if (!Candidate.prior(lhs: element, rhs: self[it])) {
                first = index(after: it)
                count -= step + 1
            } else {
                count = step
            }
        }
        
        self.insert(element, at: first)
    }
}
