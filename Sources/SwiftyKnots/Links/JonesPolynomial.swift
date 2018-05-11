//
//  JonesPolynomial.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KauffmanBracket_A: Indeterminate {
    public static let symbol = "A"
}

public struct JonesPolynomial_q: Indeterminate {
    public static let symbol = "q"
}

public typealias KauffmanBracketPolynomial = LaurentPolynomial<𝐙, KauffmanBracket_A>
public typealias JonesPolynomial = LaurentPolynomial<𝐙, JonesPolynomial_q>

public extension Link {
    
    // a polynomial in 𝐙[A, 1/A]
    public var KauffmanBracket: KauffmanBracketPolynomial {
        return _KauffmanBracket(normalized: false)
    }
    
    private func _KauffmanBracket(normalized b: Bool) -> KauffmanBracketPolynomial {
        let A = KauffmanBracketPolynomial.indeterminate
        if let x = crossings.first(where: {$0.isCrossing}) {
            let i = crossings.index(of: x)!
            let pair = splicedPair(at: i)
            return A * pair.0._KauffmanBracket(normalized: b) + A.pow(-1) * pair.1._KauffmanBracket(normalized: b)
        } else {
            let n = components.count
            return ( -A.pow(2) - A.pow(-2) ).pow(b ? n - 1 : n)
        }
    }
    
    // a polynomial in 𝐐[q, 1/q] where q = -A^{-2}
    // TODO replace with t = -q^2 = A^{-4} to get J ∈ 𝐙[√t, 1/√t]
    public var JonesPolynomial: JonesPolynomial {
        return _JonesPolynomial(normalized: true)
    }
    
    public var unnormalizedJonesPolynomial: JonesPolynomial {
        return _JonesPolynomial(normalized: false)
    }
    
    public func _JonesPolynomial(normalized b: Bool) -> JonesPolynomial {
        let A = KauffmanBracketPolynomial.indeterminate
        let f = (-A).pow( -3 * writhe ) * _KauffmanBracket(normalized: b)
        let range = -f.highestPower/2 ... -f.lowestPower/2
        let coeffs = Dictionary(keys: range) { i -> 𝐙 in
            (-1).pow(i) * f.coeff(-2 * i)
        }
        return SwiftyKnots.JonesPolynomial(coeffs: coeffs)
    }
}
