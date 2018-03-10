//
//  StiefelWhitneyClass.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/02/12.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation


public extension SimplicialComplex {
    internal func StiefelWhitneyClass(_ k: Int, _ v: [CohomologyClass<Dual<Simplex>, Z_2>]) -> CohomologyClass<Dual<Simplex>, Z_2>? {
        return (0 ... k).sum { i in
            v[i].Sq(k - i)
        }
    }
    
    public func StiefelWhitneyClass(_ k: Int) -> CohomologyClass<Dual<Simplex>, Z_2>? {
        return StiefelWhitneyClass(k, WuClasses)
    }
    
    public var StiefelWhitneyClasses: [CohomologyClass<Dual<Simplex>, Z_2>] {
        return validDims.flatMap { k in StiefelWhitneyClass(k, WuClasses) }
    }
    
    public var totalStiefelWhitneyClass: CohomologyClass<Dual<Simplex>, Z_2> {
        return StiefelWhitneyClasses.sumAll()
    }
}

public func w(_ i: Int, _ M: SimplicialComplex) -> CohomologyClass<Dual<Simplex>, Z_2> {
    return M.StiefelWhitneyClass(i)!
}

public func w(_ M: SimplicialComplex) -> CohomologyClass<Dual<Simplex>, Z_2> {
    return M.totalStiefelWhitneyClass
}
