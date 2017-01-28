// Swifty Algebra 
// https://github.com/taketo1024/SwiftyAlgebra
//
// Created by Taketo Sano (taketo1024)
// Licensed under CC0 1.0 Universal.

import Foundation

/*
 * Aliases populary used in Math.
 */

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

/*
 * Rational Number Sample.
 */

do {
    let a = Q(4, 5)
    let b = Q(3, 2)
    a + b
    a * b
    b / a
}

/*
 * Matrix Sample.
 */

do {
    typealias n = TPInt_2
    typealias M = Matrix<Z, n, n>
    
    let a = M(1, 2, 3, 4)
    let b = M(2, 1, 1, 2)
    a + b
    a * b
    
    a + b == b + a  // commutative
    a * b != b * a  // noncommutative
}

/*
 * Permutation Sample.
 */

typealias S_5 = Permutation<TPInt_5>

do {
    let σ = S_5(0, 1, 2) // cyclic notation
    let τ = S_5([0: 2, 1: 3, 2: 4, 3: 0, 4: 1]) // two-line notation
    
    σ[1]
    τ[2]
    
    (σ * τ) [3]  // 3 -> 0 -> 1
    (τ * σ) [3]  // 3 -> 3 -> 0
    
    σ * τ != τ * σ   // noncommutative
}

/*
 * Integer Quotient Sample
 */

struct I: IntIdeal {
    static let generator = 5
}

typealias F_5 = IntQuotientField<I>

do {
    let x: F_5 = 2
    x.inverse
    x * x.inverse == 1
}

/*
 * Polynomial Quotient Sample
 */

struct g: PolynomialIdeal {
    typealias R = Polynomial<Q>
    static let generator = R(-2, 0, 1)
}

typealias L = PolynomialQuotientField<Q, g>

struct h: PolynomialIdeal {
    typealias R = Polynomial<L>
    static let generator = R(-3, 0, 1)
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
