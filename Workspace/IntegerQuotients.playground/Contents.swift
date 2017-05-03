//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Integer Quotient Example

typealias F_5 = IntQuotientField<_5>

do {
    let x: F_5 = 2
    x.inverse
    x * x.inverse == 1
}

