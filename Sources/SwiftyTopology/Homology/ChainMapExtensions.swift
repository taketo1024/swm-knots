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

public extension GeometricComplexMap {
    public func asChainMap<R>(_ type: R.Type) -> ChainMap<Complex.Cell, Complex.Cell, R> {
        return ChainMap.uniform(degree: 0) { (cell: Complex.Cell) in
            let t = self.applied(to: cell)
            return (cell.dim == t.dim) ? .wrap(t) : .zero
        }
    }
}
