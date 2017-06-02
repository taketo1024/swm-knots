//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber

// Polynomials Example

typealias Qx = Polynomial<Q>
do {
    let f = Qx(2, 0, 1) // x^2 + 2
    let g = Qx(3, 2)    // 2x + 3
    
    f + g
    f * g
}

struct p: _Polynomial {
    typealias K = Q
    static var value: Polynomial<RationalNumber> {
        return Qx(1, 0, 1)
    }
}

typealias K = PolynomialQuotientRing<Q, p> // Q[x]/(x^2 + 1)

do {
    let a = K(Qx(0, 1))  // a = x mod (x^2 + 1)
    a * a == -1          // a^2 = -1
}