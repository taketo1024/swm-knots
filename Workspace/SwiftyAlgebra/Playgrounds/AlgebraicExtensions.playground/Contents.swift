//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Algebraic Extension Example

typealias Qx = Polynomial<Q>

struct g: _Polynomial {
    typealias K = Q
    static let value = Qx(-2, 0, 1)
}

typealias L = PolynomialQuotientField<Q, g>
typealias Lx = Polynomial<L>

struct h: _Polynomial {
    typealias K = L
    static let value = Lx(-3, 0, 1)
}

typealias M = PolynomialQuotientField<L, h>

do {
    let a = L(Qx(0, 1))
    a * a == 2
    
    let b = M(Lx(a, 0))
    let c = M(Lx(0, 1))
    
    b * b == 2
    c * c == 3
    
    let d = b * c
    let x = b + c
    x * x == 5 + 2 * d
}
