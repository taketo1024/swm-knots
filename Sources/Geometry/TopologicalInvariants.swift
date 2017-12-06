//
//  TopologicalInvariants.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// Topological Invariants
public extension GeometricComplex {
    public var eulerNumber: Int {
        return (0 ... dim).sum{ i in (-1).pow(i) * cells(ofDim: i).count }
    }

    public func eulerNumber<R: EuclideanRing>(_ type: R.Type) -> R {
        return R(intValue: eulerNumber)
    }
    
    public var isOrientable: Bool {
        return orientationCycle != nil
    }
    
    public func isOrientable<R: EuclideanRing>(_ type: R.Type) -> Bool {
        return orientationCycle(R.self) != nil
    }
    
    public var orientationCycle: FreeModule<Cell, IntegerNumber>? {
        return fundamentalClass?.representative
    }
    
    public func orientationCycle(relativeTo L: Self) -> FreeModule<Cell, IntegerNumber>? {
        return fundamentalClass(relativeTo:L)?.representative
    }
    
    public func orientationCycle<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> FreeModule<Cell, R>? {
        return fundamentalClass(relativeTo: L, R.self)?.representative
    }
    
    public var fundamentalClass: HomologyClass<Cell, IntegerNumber>? {
        return fundamentalClass(IntegerNumber.self)
    }
    
    public func fundamentalClass(relativeTo L: Self) -> HomologyClass<Cell, IntegerNumber>? {
        return fundamentalClass(relativeTo: L, IntegerNumber.self)
    }
    
    public func fundamentalClass<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> HomologyClass<Cell, R>? {
        let H = Homology(self, R.self)
        let summand = H[dim].summands
        
        if summand.count == 1 && summand[0].isFree {
            return HomologyClass(summand[0].generator, H)
        } else {
            return nil
        }
    }
}

// Commonly used symbols in Math.
public func χ<G: GeometricComplex>(_ M: G) -> IntegerNumber {
    return M.eulerNumber
}

public func χ<G: GeometricComplex, R: EuclideanRing>(_ M: G, _ type: R.Type) -> R {
    return M.eulerNumber(R.self)
}

public func μ<G: GeometricComplex>(_ M: G) -> HomologyClass<G.Cell, IntegerNumber> {
    return M.fundamentalClass!
}

public func μ<G: GeometricComplex, R: EuclideanRing>(_ M: G, _ type: R.Type) -> HomologyClass<G.Cell, R> {
    return M.fundamentalClass(R.self)!
}

// TODO absract up to GeometricComplex
public extension SimplicialComplex {
    public var eulerClass: CohomologyClass<Dual<Simplex>, IntegerNumber>? {
        return eulerClass(IntegerNumber.self)
    }
    
    public func eulerClass<R: EuclideanRing>(_ type: R.Type) -> CohomologyClass<Dual<Simplex>, R>? {
        
        // See [Milnor-Stasheff: Characteristic Classes §11]
        
        let M = self
        let d = SimplicialMap.diagonal(from: M)
        
        let MxM = M × M
        let ΔM = d.image
        
        let cH = Cohomology(MxM, MxM - ΔM, R.self)
        let summands = cH[dim].summands
        
        if summands.count == 1 && summands[0].isFree {
            let u = summands[0].generator                // the Diagonal cohomology class of M
            let e = d.asCochainMap(R.self).appliedTo(u)  // the Euler class of M
            return CohomologyClass(e, Cohomology(self, R.self))
        } else {
            return nil
        }
    }
}

public func e(_ M: SimplicialComplex) -> CohomologyClass<Dual<Simplex>, IntegerNumber> {
    return M.eulerClass!
}

public func e<R: EuclideanRing>(_ M: SimplicialComplex, _ type: R.Type) -> CohomologyClass<Dual<Simplex>, R> {
    return M.eulerClass(R.self)!
}
