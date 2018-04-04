//
//  JonesPolynomial.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public extension Link {
    
    // a polynomial in 𝐐[A, 1/A]
    public var KauffmanBracket: LaurentPolynomial<𝐐> {
        return _KauffmanBracket(normalized: false)
    }
    
    private func _KauffmanBracket(normalized b: Bool) -> LaurentPolynomial<𝐐> {
        let A = LaurentPolynomial<𝐐>.indeterminate
        if let J = junctions.first(where: {$0.isCrossing}) {
            let i = junctions.index(of: J)!
            let pair = splicedPair(at: i)
            return A * pair.0._KauffmanBracket(normalized: b) + A.pow(-1) * pair.1._KauffmanBracket(normalized: b)
        } else {
            let n = b ? components - 1 : components
            return ( -A.pow(2) - A.pow(-2) ).pow(n)
        }
    }
    
    // a polynomial in 𝐐[q, 1/q] where q = -A^{-2}
    // TODO replace with t = -q^2 = A^{-4} to get J ∈ 𝐐[√t, 1/√t]
    public var JonesPolynomial: LaurentPolynomial<𝐐> {
        return _JonesPolynomial(normalized: true)
    }
    
    public var unnormalizedJonesPolynomial: LaurentPolynomial<𝐐> {
        return _JonesPolynomial(normalized: false)
    }
    
    public func _JonesPolynomial(normalized b: Bool) -> LaurentPolynomial<𝐐> {
        let A = LaurentPolynomial<𝐐>.indeterminate
        let f = (-A).pow( -3 * writhe ) * _KauffmanBracket(normalized: b)
        let J = LaurentPolynomial(lowerDegree: -f.upperDegree/2, upperDegree: -f.lowerDegree/2) { i in
            𝐐(from: (-1).pow(i)) * f.coeff(-2 * i)
        }
        return J
    }
}
