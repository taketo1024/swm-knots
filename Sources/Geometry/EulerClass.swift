//
//  TopologicalInvariants.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public extension GeometricComplex {
    public var eulerNumber: Int {
        return validDims.sum{ i in (-1).pow(i) * cells(ofDim: i).count }
    }

    public func eulerNumber<R: EuclideanRing>(_ type: R.Type) -> R {
        return R(intValue: eulerNumber)
    }
}

public func χ<G: GeometricComplex>(_ M: G) -> IntegerNumber {
    return M.eulerNumber
}

public func χ<G: GeometricComplex, R: EuclideanRing>(_ M: G, _ type: R.Type) -> R {
    return M.eulerNumber(R.self)
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
        let top = cH[dim]
        
        if top.isFree && top.rank == 1 {
            let u = top.generator(0).representative
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
