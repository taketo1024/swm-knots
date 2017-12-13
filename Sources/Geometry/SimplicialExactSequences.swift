//
//  SimplicialExactSequences.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/13.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public extension HomologyExactSequence where chainType == Descending, A == Simplex {
    public init(_ X: SimplicialComplex, _ A: SimplicialComplex, _ type: R.Type) {
        let CA  = ChainComplex(A, type)
        let CX  = ChainComplex(X, type)
        let CXA = ChainComplex(X, A, type)
        
        let i = ChainMap(SimplicialMap.inclusion(from: A, to: X), R.self)
        let j = ChainMap(from: CX, to: CXA) { s in
            CXA.chainBasis(s.degree).contains(s) ? [(s, R.identity)] : []
        }
        let d = ChainMap(from: CXA, to: CA, shift: -1) { s in
            s.boundary(R.self).map{ ($0.0, $0.1) }
        }
        
        self.init(CA, i, CX, j, CXA, d)
    }
}
