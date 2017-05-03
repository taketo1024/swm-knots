//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber

// Rational Number Sample.

do {
    let a = Q(4, 5)
    let b = Q(3, 2)
    a + b
    a * b
    b / a
}

typealias R = Polynomial<Q>
let x = R.indeterminate
let f = Q(2) * x + Q(3) * x**2
