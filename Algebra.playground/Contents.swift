//: Playground - noun: a place where people can play

import Foundation

/*
 * Aliases populary used in Math.
 */

typealias ℕ = UInt
typealias ℤ = Integer
typealias ℚ = RationalNumber
typealias ℝ = RealNumber

/*
 * Rational Number Sample.
 */

do {
    let a = ℚ(4, 5)
    let b = ℚ(3, 2)
    a + b
    a * b
    b / a
}

/*
 * Matrix Sample.
 */

do {
    typealias n = TPInt_2
    typealias M = Matrix<ℤ, n, n>
    
    let a = M(1, 2, 3, 4)
    let b = M(2, 1, 1, 2)
    a + b
    a * b
}

/*
 * Permutation Sample.
 */

typealias 𝔖_5 = Permutation<TPInt_5>

do {
    let σ = 𝔖_5(0, 1, 2) // cyclic notation
    let τ = 𝔖_5([0: 2, 1: 3, 2: 4, 3: 0, 4: 1]) // two-line notation
    
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

typealias ℤ_5 = IntQuotient<I>
typealias 𝔽_5 = IntQuotientField<I>

do {
    let a: ℤ_5 = 2
    let b: ℤ_5 = 4
    let c: ℤ_5 = 8
    
    a + b
    a * b
    
    let x: 𝔽_5 = 2
    x.inverse
    x * x.inverse == 1
}

/*
 * Polynominal Quotient Sample
 */

struct g: PolynominalIdeal {
    typealias R = Polynominal<ℚ>
    static let generator = R(-2, 0, 1)
}

typealias L = PolynominalQuotientField<ℚ, g>

struct h: PolynominalIdeal {
    typealias R = Polynominal<L>
    static let generator = R(-3, 0, 1)
}

typealias M = PolynominalQuotientField<L, h>

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
