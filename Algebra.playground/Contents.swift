//: Playground - noun: a place where people can play

import Foundation

typealias ℕ = UInt
typealias ℤ = Integer
typealias ℚ = RationalNumber
typealias ℝ = RealNumber

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
    x * x.inverse == 1
}

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
