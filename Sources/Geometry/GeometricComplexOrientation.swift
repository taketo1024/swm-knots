//
//  OrientationClass.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/02/12.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public extension GeometricComplex {
    public var isOrientable: Bool {
        return orientationCycle != nil
    }
    
    public func isOrientable(relativeTo L: Self) -> Bool {
        return orientationCycle(relativeTo: L) != nil
    }
    
    public func isOrientable<R: EuclideanRing>(relativeTo L: Self?, _ type: R.Type) -> Bool {
        return orientationCycle(relativeTo: L, R.self) != nil
    }
    
    public var orientationCycle: FreeModule<Cell, IntegerNumber>? {
        return orientationClass?.representative
    }
    
    public func orientationCycle(relativeTo L: Self) -> FreeModule<Cell, IntegerNumber>? {
        return orientationClass(relativeTo:L)?.representative
    }
    
    public func orientationCycle<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> FreeModule<Cell, R>? {
        return orientationClass(relativeTo: L, R.self)?.representative
    }
    
    public var orientationClass: HomologyClass<Cell, IntegerNumber>? {
        return orientationClass(IntegerNumber.self)
    }
    
    public func orientationClass(relativeTo L: Self) -> HomologyClass<Cell, IntegerNumber>? {
        return orientationClass(relativeTo: L, IntegerNumber.self)
    }
    
    public func orientationClass<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> HomologyClass<Cell, R>? {
        let H = (L == nil) ? Homology(self, R.self) : Homology(self, L!, R.self)
        let top = H[dim]
        
        if top.isFree && top.rank == 1 {
            return top.generator(0)
        } else {
            return nil
        }
    }
}

public func μ<G: GeometricComplex>(_ M: G) -> HomologyClass<G.Cell, IntegerNumber> {
    return M.orientationClass!
}

public func μ<G: GeometricComplex, R: EuclideanRing>(_ M: G, _ type: R.Type) -> HomologyClass<G.Cell, R> {
    return M.orientationClass(R.self)!
}
