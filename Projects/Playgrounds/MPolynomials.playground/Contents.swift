//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Multivariate Polynomials Example

typealias P = MPolynomial<𝐐>

let f = P(([1   ], 1), ([0, 1], 3))    //
let g = P(([2, 1], 1), ([0, 0, 1], 1))

f + g
f * g

