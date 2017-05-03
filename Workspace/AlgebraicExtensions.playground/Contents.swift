//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Algebraic Extension Example

struct g: _Polynomial {
    typealias K = Q
    static let value = Polynomial<Q>(-2, 0, 1)
}

typealias L = PolynomialQuotientField<Q, g>

struct h: _Polynomial {
    typealias K = L
    static let value = Polynomial<L>(-3, 0, 1)
}

typealias M = PolynomialQuotientField<L, h>

do {
    let a = L(0, 1)
    a * a == 2
    
    let b = M(a, 0)
    let c = M(0, 1)
    
    b * b == 2
    c * c == 3
    
    let d = b * c
    let x = b + c
    x * x == 5 + 2 * d
}
