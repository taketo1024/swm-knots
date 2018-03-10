//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber

// Multivariate Polynomials Example

typealias A = MPolynomial<Q>

let f = A(([1   ], 1), ([0, 1], 3))    //
let g = A(([2, 1], 1), ([0, 0, 1], 1))

f + g
f * g

