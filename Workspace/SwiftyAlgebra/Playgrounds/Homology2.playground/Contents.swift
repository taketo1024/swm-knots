//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Coeff Ring
typealias G = Z
//typealias G = Z_2
//typealias G = Q

do {
    let n = 2
    let X = SimplicialComplex.torus(dim: n)
    let s = X.cells(ofDim: n)[0]
    
    let A = (X - s).named("A")
    let B = s.asComplex.named("B")
    
    var E = HomologyExactSequence.MayerVietoris(X, A, B, G.self)
    
    E.fill(column: 0)
    E.fill(column: 1)
    
    print("\nbefore:")
    print(E.detailDescription, "\n")
    
    E.solve(debug: true)
    
    print("\nresult:")
    print(E.detailDescription, "\n")
}
