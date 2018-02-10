//
//  SimplicialCohomologyRing.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/02/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

// TODO conform to Ring after conditional-conformance is supported.

public extension CohomologyClass where chainType == Ascending, A == Dual<Simplex> {
    public func cup(_ b: CohomologyClass<A, R>) -> CohomologyClass<A, R> {
        let a = self
        guard let H1 = a.structure, let H2 = b.structure else {
            return CohomologyClass.zero
        }
        
        assert(H1 == H2)
        
        let x = a.representative.cup(b.representative)
        return CohomologyClass<A, R>(x, H1)
    }
    
    public static func *(a: CohomologyClass<A, R>, b: CohomologyClass<A, R>) -> CohomologyClass<A, R> {
        return a.cup(b)
    }
    
    public static func ∪(a: CohomologyClass<A, R>, b: CohomologyClass<A, R>) -> CohomologyClass<A, R> {
        return a.cup(b)
    }

    public func cap(_ x: HomologyClass<Simplex, R>) -> HomologyClass<Simplex, R> {
        guard let _ = self.structure, let H2 = x.structure else {
            return HomologyClass.zero
        }
        
        // TODO check H1, H2 matches.
        
        let y = self.representative.cap(x.representative)
        return HomologyClass<Simplex, R>(y, H2)
    }
    
    public static func ∩(a: CohomologyClass<A, R>, x: HomologyClass<Simplex, R>) -> HomologyClass<Simplex, R> {
        return a.cap(x)
    }
}
