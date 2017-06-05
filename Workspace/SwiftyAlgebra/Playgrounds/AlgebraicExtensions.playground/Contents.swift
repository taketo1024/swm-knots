//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Algebraic Extension Example

typealias Qx = Polynomial<Q>

struct p1: _IrreduciblePolynomial {
    typealias K = Q
    static let value = Qx(-2, 0, 1)
}

typealias K1 = AlgebraicExtension<Q, p1>
typealias K1x = Polynomial<K1>

struct p2: _IrreduciblePolynomial {
    typealias K = K1
    static let value = K1x(-3, 0, 1)
}

typealias K2 = AlgebraicExtension<K1, p2>

do {
    let a = K1(Qx(0, 1))
    a * a == 2
    
    let b = K2(K1x(a, 0))
    let c = K2(K1x(0, 1))
    
    b * b == 2
    c * c == 3
    
    let d = b * c
    let x = b + c
    x * x == 5 + 2 * d
}
