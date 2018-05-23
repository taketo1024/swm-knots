//
//  OrientationClass.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/02/12.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension GeometricComplex {
    public var eulerNumber: Int {
        return validDims.sum{ i in (-1).pow(i) * cells(ofDim: i).count }
    }
    
    public func eulerNumber<R: EuclideanRing>(_ type: R.Type) -> R {
        return R(from: eulerNumber)
    }
    
    public var isOrientable: Bool {
        return orientationCycle != nil
    }
    
    public func isOrientable(relativeTo L: Self) -> Bool {
        return orientationCycle(relativeTo: L) != nil
    }
    
    public func isOrientable<R: EuclideanRing>(relativeTo L: Self?, _ type: R.Type) -> Bool {
        return orientationCycle(relativeTo: L, R.self) != nil
    }
    
    public var orientationCycle: FreeModule<Cell, 𝐙>? {
        return orientationCycle(relativeTo: nil, 𝐙.self)
    }
    
    public func orientationCycle(relativeTo L: Self) -> FreeModule<Cell, 𝐙>? {
        return orientationCycle(relativeTo: L, 𝐙.self)
    }
    
    public func orientationCycle<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> FreeModule<Cell, R>? {
        let H = self.homology(relativeTo: L, R.self)
        if let top = H[dim], top.isFree, top.rank == 1 {
            return top.generator(0)
        } else {
            return nil
        }
    }
}
