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

/*
public extension ChainMap where T == Descending {
    public static func induced<F: GeometricComplexMap>(from f: F, _ type: R.Type) -> ChainMap<A, B, R> where A == F.Complex.Cell, B == F.Complex.Cell {
        typealias Cell = F.Complex.Cell
        return ChainMap { (s: Cell) -> Codomain in
            let t = f.applied(to: s)
            return (s.dim == t.dim) ? Codomain(t) : Codomain.zero
        }
    }
}

public extension CochainMap where T == Ascending {
    public static func induced<F: GeometricComplexMap>(from f: F, domainComplex: ChainComplex<F.Complex.Cell, R>, _ type: R.Type) -> CochainMap<A, B, R> where A == Dual<F.Complex.Cell>, B == Dual<F.Complex.Cell> {
        typealias Cell = F.Complex.Cell
        return ChainMap.induced(from: f, R.self).dual(domain: domainComplex)
    }
}
*/
