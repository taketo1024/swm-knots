//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Matrix Example

do {
    typealias M = Matrix<_2,_2, Z>
    
    let a = M(grid:[1, 2, 3, 4])
    let b = M(2, 1, 1, 2)
    a + b
    a * b
    
    a + b == b + a  // commutative
    a * b != b * a  // noncommutative
    
    a.determinant
    b.determinant

    let c = Matrix<_3,_3, Z>(1,2,3,0,-4,1,0,3,-1)
    
    c.determinant
    c.isInvertible
    c * c.inverse! == Matrix.identity
}

// Matrix Elimination

do {
    typealias M = Matrix<_3,_3, Z>
    
    let A = M(1, -2, -6, 2, 4, 12, 1, -4, -12)
    let E = A.smithNormalForm
    let (B, P, Q) = (E.result, E.left, E.right)
    
    B == P * A * Q
    
    let kernel = A.kernelVectors.first!
    A * kernel == ColVector<_3, Z>.zero
}
