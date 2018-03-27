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
    public convenience init<C: GeometricComplex>(geometricComplex K: C, relativeTo L: C?, _ type: R.Type) where A == C.Cell {
        let name = (L == nil) ? K.name : "\(K.name), \(L!.name)"
        let chain = K.validDims.map{ (i) -> (ChainBasis, BoundaryMap) in
            let basis = (L == nil)
                ? K.cells(ofDim: i)
                : K.cells(ofDim: i).subtract(L!.cells(ofDim: i))
            let map = K.boundaryMap(i, R.self)
            return (basis, map)
        }
        self.init(name: name, chain: chain)
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where A == C.Cell {
        self.init(geometricComplex: K, relativeTo: nil, R.self)
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ L: C, _ type: R.Type) where A == C.Cell {
        self.init(geometricComplex: K, relativeTo: L, R.self)
    }
}

public extension ChainMap where T == Descending {
    public static func induced<F: GeometricComplexMap>(from f: F, _ type: R.Type) -> ChainMap<A, B, R> where A == F.ComplexType.Cell, B == F.ComplexType.Cell {
        typealias Cell = F.ComplexType.Cell
        return ChainMap { (s: Cell) -> Codomain in
            let t = f.applied(to: s)
            return (s.dim == t.dim) ? Codomain(t) : Codomain.zero
        }
    }
}

public extension CochainMap where T == Ascending {
    public static func induced<F: GeometricComplexMap>(from f: F, domainComplex: ChainComplex<F.ComplexType.Cell, R>, _ type: R.Type) -> CochainMap<A, B, R> where A == Dual<F.ComplexType.Cell>, B == Dual<F.ComplexType.Cell> {
        typealias Cell = F.ComplexType.Cell
        return ChainMap.induced(from: f, R.self).dual(domain: domainComplex)
    }
}

public extension Homology where T == Descending {
    public convenience init<C: GeometricComplex>(geometricComplex K: C, relativeTo L: C?, _ type: R.Type) where A == C.Cell {
        self.init(ChainComplex(geometricComplex: K, relativeTo: L, R.self))
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where A == C.Cell {
        self.init(geometricComplex: K, relativeTo: nil, R.self)
    }

    public convenience init<C: GeometricComplex>(_ K: C, _ L: C, _ type: R.Type) where A == C.Cell {
        self.init(geometricComplex: K, relativeTo: L, R.self)
    }
}

public extension Cohomology where T == Ascending {
    public convenience init<C: GeometricComplex>(geometricComplex K: C, relativeTo L: C?, _ type: R.Type) where A == Dual<C.Cell> {
        self.init(ChainComplex(geometricComplex: K, relativeTo: L, R.self).dual)
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where A == Dual<C.Cell> {
        self.init(geometricComplex: K, relativeTo: nil, R.self)
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ L: C, _ type: R.Type) where A == Dual<C.Cell> {
        self.init(geometricComplex: K, relativeTo: L, R.self)
    }
}

public extension HomologyMap where T == Descending {
    public static func induced<F: GeometricComplexMap>(from f: F, codomainStructure H: Homology<B, R>, _ type: R.Type) -> HomologyMap<A, B, R> where A == F.ComplexType.Cell, B == F.ComplexType.Cell {
        return HomologyMap.induced(from: ChainMap.induced(from: f, R.self), codomainStructure: H)
    }
}

public extension CohomologyMap where T == Ascending {
    public static func induced<F: GeometricComplexMap>(from f: F, domainComplex: ChainComplex<F.ComplexType.Cell, R>, domainStructure H: Cohomology<A, R>, _ type: R.Type) -> CohomologyMap<A, B, R> where A == Dual<F.ComplexType.Cell>, B == Dual<F.ComplexType.Cell> {
        return CohomologyMap.induced(from: ChainMap.induced(from: f, R.self).dual(domain: domainComplex), codomainStructure: H)
    }
}
