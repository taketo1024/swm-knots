//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Matrix Example

do {
    typealias M = Matrix<Z,_2,_2>
    
    let a = M(1, 2, 3, 4)
    let b = M(2, 1, 1, 2)
    a + b
    a * b
    
    a + b == b + a  // commutative
    a * b != b * a  // noncommutative
}
