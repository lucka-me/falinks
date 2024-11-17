//
//  Candidate.swift
//  AdministrativeSphereBuilder
//
//  Created by Lucka on 17/10/2024.
//

import SphereGeometry

struct Candidate {
    let cell: Cell
    let identifier: CellIdentifier
    
    let intersectedChildren: [ Cell ]
    let containedChildren: [ Cell ]
    
    init(cell: Cell, for geometry: CellAlgebra) {
        self.cell = cell
        self.identifier = cell.identifier
        var intersectedChildren: [ Cell ] = [ ]
        var containedChildren: [ Cell ] = [ ]
        for child in cell.children {
            switch geometry.relation(with: child) {
            case .intersect:
                intersectedChildren.append(child)
            case .contain:
                containedChildren.append(child)
            default:
                break
            }
        }
        
        self.intersectedChildren = intersectedChildren
        self.containedChildren = containedChildren
    }
}

extension Candidate {
    static func prior(lhs: Self, rhs: Self) -> Bool {
        lhs.priority < rhs.priority
    }
                
    var availableChildrenCount: Int {
        intersectedChildren.count + containedChildren.count
    }
    
    var coveringMoreThanHalf: Bool {
        intersectedChildren.count + containedChildren.count * 2 >= 4
    }
    
    var priority: Int {
        (Int(cell.level.rawValue) << 6) + (intersectedChildren.count << 3)  + (containedChildren.count)
    }
}
