//
//  SymmetricPolynomials.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public extension MPolynomial {
    public static func elementarySymmetricPolynomial(_ n: Int, _ i: Int) -> MPolynomial<K> {
        let mInds = n.choose(i).map { combi -> MIndex in
            // e.g.  [0, 1, 3] -> (1, 1, 0, 1)
            let l = combi.last.flatMap{ $0 + 1 } ?? 0
            return MIndex( (0 ..< l).map { combi.contains($0) ? 1 : 0 } )
        }
        
        let coeffs = Dictionary(pairs: mInds.map{ ($0, K.identity) } )
        return MPolynomial(coeffs)
    }
    
    public static func monomialSymmetricPolynomial(_ n: Int, _ I: MIndex) -> MPolynomial<K> {
        let ss = DynamicPermutation.allElements(size: n)
        let Js = ss.map{ s -> MIndex in
            let indices = I.indices.enumerated().map{ (i, j) in (s.apply(i), j)}
            return MIndex(Dictionary(pairs: indices))
        }.unique()
        let elements = Dictionary(keys: Js){ _ in K.identity }
        return MPolynomial(elements)
    }
    
    public func elementarySymmetricPolynomialDecomposition() -> MPolynomial<K> {
        var f = self
        var g = MPolynomial<K>.zero // result
        
        let n = f.numberOfIndeterminates
        let s = MPolynomial.elementarySymmetricPolynomial
        
        while f.maxDegree > 0 {
            let I = f.leadDegree
            let a = f.leadCoeff

            // If I = (i1, i2, ... ik),
            // then i1 >= i2 >= ... >= ik must hold.
            //
            // Let c = (i1 - i2, i2 - i3, ..., i{k-1} - ik, ik),
            // then p = s1^c1 * s2^c2 * ... * sk^ck  is a sym. poly. with leadDeg = i.
            
            let c = (0 ..< I.length).map{ j in (j < n) ? I[j] - I[j + 1] : I[j]  }
            let p = c.enumerated().map{ (j, cj) in s(n, j + 1) ** cj }.multiplyAll()
            
            f = f - a * p
            g = g + a * MPolynomial(MIndex(c))

            assert(f.leadDegree < I)
        }
        
        return g + f
    }
}
