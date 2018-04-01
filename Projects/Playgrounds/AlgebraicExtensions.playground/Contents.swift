//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Algebraic extensions over 𝐐:

do {
    // K1 = 𝐐[x]/(x^2 - 2) = 𝐐(√2).
    
    struct p1: _IrreduciblePolynomial {                 // p1 = x^2 - 2
        static let value = Polynomial<𝐐>(-2, 0, 1)
    }
    
    typealias K1 = AlgebraicExtension<𝐐, p1>
    K1.isField
    
    let a = Polynomial<𝐐>(0, 1).asQuotient(in: K1.self) // a = x mod I
    a * a == 2                                          // a = √2
    
    // K2 = K1[x]/(x^2 - 3) = K1(√3) = 𝐐(√2, √3).
    
    struct p2: _IrreduciblePolynomial {                // p2 = x^2 - 3
        static let value = Polynomial<K1>(-3, 0, 1)
    }
    
    typealias K2 = AlgebraicExtension<K1, p2>
    K2.isField
    
    let b = Polynomial<K1>(0, 1).asQuotient(in: K2.self) // b = x mod I2
    b * b == 3                                           // b = √3
}
