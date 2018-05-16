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

public extension Homology where T == Descending {
    public convenience init<C: GeometricComplex>(geometricComplex K: C, relativeTo L: C?, _ type: R.Type) where A == C.Cell {
        let name = "H(\(K.name)\( L != nil ? ", \(L!.name)" : ""); \(R.symbol))"
        self.init(name: name, chainComplex: ChainComplex(geometricComplex: K, relativeTo: L, R.self))
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
        let name = "cH(\(K.name)\( L != nil ? ", \(L!.name)" : ""); \(R.symbol))"
        self.init(name: name, chainComplex: ChainComplex(geometricComplex: K, relativeTo: L, R.self).dual)
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where A == Dual<C.Cell> {
        self.init(geometricComplex: K, relativeTo: nil, R.self)
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ L: C, _ type: R.Type) where A == Dual<C.Cell> {
        self.init(geometricComplex: K, relativeTo: L, R.self)
    }
}
