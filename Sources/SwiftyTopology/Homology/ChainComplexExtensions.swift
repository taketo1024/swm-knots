//
//  GeometricComplexExtensions.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/02/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension GeometricComplex {
    public func chainComplex<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> GradedChainComplex<Cell, R> {
        if let L = L { // relative: (K, L)
            return _chainComplex(relativeTo: L, R.self)
        } else {
            return _chainComplex(R.self)
        }
    }

    private func _chainComplex<R: EuclideanRing>(_ type: R.Type) -> GradedChainComplex<Cell, R> {
        let name = "C(\(self.name); \(R.symbol))"
        let list = validDims.map { i in cells(ofDim: i) }
        let base = GradedModuleStructure<Cell, R>(name: name, list: list)
        return base.asChainComplex(degree: -1) { (i, cell) -> FreeModule<Cell, R> in
            cell.boundary(R.self)
        }
    }
    
    private func _chainComplex<R: EuclideanRing>(relativeTo L: Self, _ type: R.Type) -> GradedChainComplex<Cell, R> {
        let name = "C(\(self.name), \(L.name); \(R.symbol))"
        let list = validDims.map { i in cells(ofDim: i).subtract(L.cells(ofDim: i)) }
        let base = GradedModuleStructure<Cell, R>(name: name, list: list)
        return base.asChainComplex(degree: -1) { (i, cell) -> FreeModule<Cell, R> in
            cell.boundary(R.self).map { (cell, r) in
                (i > 0 && list[i - 1].contains(cell)) ? (cell, r) : (cell, .zero)
            }
        }
    }
    
    public func homology<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> GradedModuleStructure<Cell, R> {
        let name = (L == nil) ? "H(\(self.name); \(R.symbol))" : "H(\(self.name), \(L!.name); \(R.symbol))"
        let C = chainComplex(relativeTo: L, R.self)
        return C.homology(name: name)
    }
}

// TODO remove old

public extension ChainComplex where T == Descending {
    public convenience init<C: GeometricComplex>(geometricComplex K: C, relativeTo L: C?, _ type: R.Type) where A == C.Cell {
        if let L = L { // relative: (K, L)
            let name = "C(\(K.name), \(L.name); \(R.symbol))"
            let chain = K.validDims.map{ (i) -> (ChainBasis, BoundaryMap) in
                let basis = K.cells(ofDim: i).subtract(L.cells(ofDim: i))
                let orig = K.boundaryMap(i, R.self)
                let map = BoundaryMap{ (c: A) in
                    orig.applied(to: c).map{ (a, r) in
                        basis.contains(a) ? (a, r) : (a, .zero)
                    }
                }
                return (basis, map)
            }
            self.init(name: name, chain: chain)
            
        } else { // absolute
            let name = "C(\(K.name); \(R.symbol))"
            let chain = K.validDims.map{ (i) -> (ChainBasis, BoundaryMap) in
                let basis = K.cells(ofDim: i)
                let map = K.boundaryMap(i, R.self)
                return (basis, map)
            }
            self.init(name: name, chain: chain)
        }
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where A == C.Cell {
        self.init(geometricComplex: K, relativeTo: nil, R.self)
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ L: C, _ type: R.Type) where A == C.Cell {
        self.init(geometricComplex: K, relativeTo: L, R.self)
    }
}
