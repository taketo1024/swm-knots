//
//  JonesPolynomial.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import SwiftyMath

public struct _A: PolynomialIndeterminate {
    public static let symbol = "A"
}

public func KauffmanBracket(_ L: Link, normalized: Bool = false) -> LaurentPolynomial<𝐙, _A> {
    typealias P = LaurentPolynomial<𝐙, _A>
    let A = P.indeterminate
    let B = -A.pow(2) - A.pow(-2)
    
    let n = L.crossingNumber
    return Link.State.allSequences(length: n).sum { s -> P in
        let L1 = L.resolved(by: s)
        let n = L1.components.count
        let c1 = s.weight
        let c0 = s.count - c1
        return A.pow(c0 - c1) * B.pow(normalized ? n - 1 : n)
    }
}

public struct _q: PolynomialIndeterminate {
    public static let symbol = "q"
}

public func JonesPolynomial(_ L: Link, normalized: Bool = true) -> LaurentPolynomial<𝐙, _q> {
    let A = LaurentPolynomial<𝐙, _A>.indeterminate
    let f = (-A).pow( -3 * L.writhe ) * KauffmanBracket(L, normalized: normalized)
    let range = -f.leadExponent / 2 ... -f.tailExponent / 2
    let coeffs = Dictionary(keys: range) { i -> 𝐙 in
        (-1).pow(i) * f.coeff(-2 * i)
    }
    return .init(coeffs: coeffs)
}
