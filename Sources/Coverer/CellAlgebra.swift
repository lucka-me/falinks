//
//  CellAlgebra.swift
//  SphereGeometry
//
//  Created by Lucka on 1/10/2024.
//

import SphereGeometry

public protocol CellAlgebra {
    func relation(with cell: Cell) -> CellRelation
}

public enum CellRelation {
    case disjoint
    case intersect
    case contain
}
