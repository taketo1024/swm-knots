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

public extension HomologyMap where T == Descending {
    public static func induced<F: GeometricComplexMap>(from f: F, codomainStructure H: Homology<B, R>, _ type: R.Type) -> HomologyMap<A, B, R> where A == F.Complex.Cell, B == F.Complex.Cell {
        return HomologyMap.induced(from: ChainMap.induced(from: f, R.self), codomainStructure: H)
    }
}

public extension CohomologyMap where T == Ascending {
    public static func induced<F: GeometricComplexMap>(from f: F, domainComplex: ChainComplex<F.Complex.Cell, R>, domainStructure H: Cohomology<A, R>, _ type: R.Type) -> CohomologyMap<A, B, R> where A == Dual<F.Complex.Cell>, B == Dual<F.Complex.Cell> {
        return CohomologyMap.induced(from: ChainMap.induced(from: f, R.self).dual(domain: domainComplex), codomainStructure: H)
    }
}
