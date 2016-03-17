//: Playground - noun: a place where people can play

import Foundation

public struct P5: IntIdeal {
    public static let generator = 5
}

typealias Z_5 = IntQuotient<P5>
let a: Z_5 = 2
let b: Z_5 = 4
let c: Z_5 = 8
a + b
a * b

typealias F_5 = IntQuotientField<P5>
let x: F_5 = 2
x * x.inverse == 1

public struct F: PolynominalIdeal {
    public typealias R = Polynominal<Q>
    public static let generator = R(1, 1, 1)
}

typealias L = PolynominalQuotientField<Q, F>
let f: L = 1
