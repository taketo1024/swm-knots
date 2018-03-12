//
//  MultiplicativeSequence.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/12.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct MultiplicativeSequence<K: Field>: CustomStringConvertible {
    internal let map: (Int) -> MPolynomial<K>
    
    public init(belongingTo f: PowerSeries<K>) {
        self.map = { n in
            let Is = n.partitions
            return Is.sum { I in
                let c = I.elements.multiply { i in f.coeff(i) }
                let s_I = SymmetricPolynomial<K>.monomial(n, I).elementaryDecomposition()
                return c * s_I
            }
        }
    }
    
    public subscript(n: Int) -> MPolynomial<K> {
        return map(n)
    }
    
    public var description: String {
        return (0 ..< 5).map{ self[$0].description }.joined(separator: " + ") + " ..."
    }
}
