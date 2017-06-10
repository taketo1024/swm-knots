//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Matrix Example

EigenAcceleration.enable(true)

do {
    typealias M = Matrix<Z,_2,_2>
    
    let a = M(1, 2, 3, 4)
    let b = M(2, 1, 1, 2)
    a + b
    a * b
    
    a + b == b + a  // commutative
    a * b != b * a  // noncommutative
}

// Matrix Elimination

do {
    typealias M = Matrix<Z,_3,_3>
    
    let A = M(1, -2, -6, 2, 4, 12, 1, -4, -12)
    let E = A.eliminate()
    let (B, P, Q) = (E.rankNormalForm, E.left, E.right)
    
    B == P * A * Q
    
    let kernel = E.kernelVectors.first!
    A * kernel == ColVector<Z, _3>.zero
}
