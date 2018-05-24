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
    public func chainComplex<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> ChainComplex<Cell, R> {
        if let L = L { // relative: (K, L)
            return _chainComplex(relativeTo: L, type)
        } else {
            return _chainComplex(R.self)
        }
    }

    private func _chainComplex<R: EuclideanRing>(_ type: R.Type) -> ChainComplex<Cell, R> {
        let name = "C(\(self.name); \(R.symbol))"
        let list = validDims.map { i in cells(ofDim: i) }
        let base = ModuleSequence<Cell, R>(name: name, list: list)
        return base.asChainComplex(degree: -1) { (i, cell) -> FreeModule<Cell, R> in
            cell.boundary(R.self)
        }
    }
    
    private func _chainComplex<R: EuclideanRing>(relativeTo L: Self, _ type: R.Type) -> ChainComplex<Cell, R> {
        let name = "C(\(self.name), \(L.name); \(R.symbol))"
        let list = validDims.map { i in cells(ofDim: i).subtract(L.cells(ofDim: i)) }
        let base = ModuleSequence<Cell, R>(name: name, list: list)
        return base.asChainComplex(degree: -1) { (i, cell) -> FreeModule<Cell, R> in
            cell.boundary(R.self).map { (cell, r) in
                (i > 0 && list[i - 1].contains(cell)) ? (cell, r) : (cell, .zero)
            }
        }
    }
    
    public func homology<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> ModuleSequence<Cell, R> {
        let name = (L == nil) ? "H(\(self.name); \(R.symbol))" : "H(\(self.name), \(L!.name); \(R.symbol))"
        let C = chainComplex(relativeTo: L, type)
        return C.homology(name: name)
    }
    
    public func cochainComplex<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> ChainComplex<Dual<Cell>, R> {
        let name = (L == nil) ? "cC(\(self.name); \(R.symbol))" : "cC(\(self.name), \(L!.name); \(R.symbol))"
        return chainComplex(relativeTo: L, type).dual(name: name)
    }
    
    public func cohomology<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> ModuleSequence<Dual<Cell>, R> {
        let name = (L == nil) ? "cH(\(self.name); \(R.symbol))" : "cH(\(self.name), \(L!.name); \(R.symbol))"
        let C = cochainComplex(relativeTo: L, type)
        return C.homology(name: name)
    }
}
