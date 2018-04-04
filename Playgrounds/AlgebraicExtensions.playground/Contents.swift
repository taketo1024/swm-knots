//: Playground - noun: a place where people can play

import Foundation
import SwiftyMath

// Algebraic extensions over 𝐐:

do {
    // K1 = 𝐐[x]/(x^2 - 2) = 𝐐(√2).

    struct p1: _IrreduciblePolynomial {      // p1 = x^2 - 2
        static let value = Polynomial<𝐐>(-2, 0, 1)
    }

    typealias K1 = AlgebraicExtension<𝐐, p1>
    K1.isField

    let a = K1(Polynomial<𝐐>.indeterminate)  // a = x mod I
    a * a == 2                               // a = √2
    
    // K2 = K1[x]/(x^2 - 3) = K1(√3) = 𝐐(√2, √3).

    struct p2: _IrreduciblePolynomial {      // p2 = x^2 - 3
        static let value = Polynomial<K1>(-3, 0, 1)
    }

    typealias K2 = AlgebraicExtension<K1, p2>
    K2.isField

    let b = K2(Polynomial<K1>.indeterminate) // b = x mod I2
    b * b == 3                               // b = √3
}
