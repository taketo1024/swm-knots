//: Playground - noun: a place where people can play

import Foundation
import SwiftyMath

// Polynomials Example

// Univariate Polynomials
do {
    typealias P = Polynomial<𝐐>
    let f = P(2, 0, 1) // x^2 + 2
    let g = P(3, 2)    // 2x + 3
    
    f + g
    f * g
}

// Multivariate Polynomials
do {
    typealias P = MPolynomial<𝐐>
    
    let f = P(([1   ], 1), ([0, 1], 3))    //
    let g = P(([2, 1], 1), ([0, 0, 1], 1))
    
    f + g
    f * g
}
