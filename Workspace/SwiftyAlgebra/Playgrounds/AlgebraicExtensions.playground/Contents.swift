//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Static AlgebraicExtension (need to define a struct)
// K = Q[x]/(x^2 + 1) = Q(i)
do {
    struct p: _Polynomial {
        typealias K = Q
        static let value = Polynomial<Q>(1, 0, 1)
    }
    
    typealias I = PolynomialIdeal<Q, p>
    typealias K = AlgebraicExtension<Q, I>
    
    let i = Polynomial<Q>(0, 1).asQuotient(in: K.self)
    i * i == -1
}

// Dynamic AlgebraicExtension
// K = Q[x]/(x^2 - 2) = Q(√2)
do {
    typealias I = DynamicIdeal<Polynomial<Q>, _0>
    I.register(Polynomial<Q>(-2, 0, 1).asIdeal)
    
    typealias K = AlgebraicExtension<Q, I>
    
    let a = Polynomial<Q>(0, 1).asQuotient(in: K.self)
    a * a == 2
}