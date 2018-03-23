//
//  GeometricComplexExtensions.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/02/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyAlgebra

public extension ChainComplex where T == Descending {
    public init<C: GeometricComplex>(_ K: C, _ L: C? = nil) where A == C.Cell {
        let name = (L == nil) ? K.name : "\(K.name), \(L!.name)"
        let chain = K.validDims.map{ (i) -> (ChainBasis, BoundaryMap) in
            let basis = (L == nil)
                ? K.cells(ofDim: i)
                : K.cells(ofDim: i).subtract(L!.cells(ofDim: i))
            let map = K.boundaryMap(i, R.self)
            return (basis, map)
        }
        self.init(name: name, chain)
    }
}

public extension ChainMap where T == Descending {
    public static func induced<F: GeometricComplexMap>(from f: F) -> ChainMap<A, B, R> where A == F.ComplexType.Cell, B == F.ComplexType.Cell {
        typealias Cell = F.ComplexType.Cell
        return ChainMap { (s: Cell) -> Codomain in
            let t = f.applied(to: s)
            return (s.dim == t.dim) ? Codomain(t) : Codomain.zero
        }
    }
}

public extension Homology where T == Descending {
    public convenience init<C: GeometricComplex>(_ K: C, _ L: C? = nil) where A == C.Cell {
        self.init(ChainComplex(K, L))
    }
}

public extension Cohomology where T == Ascending {
    public convenience init<C: GeometricComplex>(_ K: C, _ L: C? = nil) where A == Dual<C.Cell> {
        self.init(ChainComplex<C.Cell, R>(K, L).dual)
    }
}

public extension HomologyMap where T == Descending {
    public static func induced<F: GeometricComplexMap>(from f: F, codomainStructure H: Homology<B, R>) -> HomologyMap<A, B, R> where A == F.ComplexType.Cell, B == F.ComplexType.Cell {
        return HomologyMap.induced(from: ChainMap.induced(from: f), codomainStructure: H)
    }
}

public extension CohomologyMap where T == Ascending {
    public static func induced<F: GeometricComplexMap>(from f: F, domainComplex: ChainComplex<F.ComplexType.Cell, R>, domainStructure H: Cohomology<A, R>) -> CohomologyMap<A, B, R> where A == Dual<F.ComplexType.Cell>, B == Dual<F.ComplexType.Cell> {
        return CohomologyMap.induced(from: ChainMap.induced(from: f).dual(domain: domainComplex), codomainStructure: H)
    }
}
