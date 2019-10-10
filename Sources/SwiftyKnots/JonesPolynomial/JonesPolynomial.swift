//
//  JonesPolynomial.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct _q: PolynomialIndeterminate {
    public static let symbol = "q"
}

public typealias JonesPolynomial = LaurentPolynomial<_q, 𝐙>

extension Link {
    // a polynomial in 𝐐[q, 1/q] where q = -A^{-2}
    // TODO replace with t = -q^2 = A^{-4} to get J ∈ 𝐙[√t, 1/√t]
    public var JonesPolynomial: JonesPolynomial {
        return JonesPolynomial(normalized: true)
    }
    
    public func JonesPolynomial(normalized b: Bool) -> JonesPolynomial {
        let A = KauffmanBracketPolynomial.indeterminate
        let f = (-A).pow( -3 * writhe ) * KauffmanBracket(normalized: b)
        let range = -f.highestExponent / 2 ... -f.lowestExponent / 2
        let coeffs = Dictionary(keys: range) { i -> 𝐙 in
            (-1).pow(i) * f.coeff(-2 * i)
        }
        return SwiftyKnots.JonesPolynomial(coeffs: coeffs)
    }
}
