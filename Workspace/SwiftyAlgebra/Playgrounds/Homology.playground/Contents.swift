//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

typealias H = Homology
//typealias H = Cohomology // switch to get results for cohomology.


// D^3 = Δ^3
do {
    let D3 = SimplicialComplex.ball(dim: 3)
    let h =  H(D3, Z.self)
    print("H(D^3; Z) =", h.detailDescription, "\n")
}

// S^2 = ∂Δ^3
do {
    let S2 = SimplicialComplex.sphere(dim: 2)
    let h =  H(S2, Z.self)
    print("H(S^2; Z) =", h.detailDescription, "\n")
}

// (D^3, S^2) relative
do {
    let D3 = SimplicialComplex.ball(dim: 3)
    let S2 = D3.skeleton(2)
    let h  = H(D3, S2, Z.self)
    print("H(D^3, S^2; Z) =", h.detailDescription, "\n")
}

// T^2 = S^1 x S^1
do {
    let T2 = SimplicialComplex.torus(dim: 2)
    let h =  H(T2, Z.self)
    print("H(T^2; Z) =", h.detailDescription, "\n")
}

// RP^2
do {
    let RP2 = SimplicialComplex.realProjectiveSpace(dim: 2)
    let h1  = H(RP2, Z.self)
    print("H(RP^2; Z) =", h1.detailDescription, "\n")
    
    let h2 = H(RP2, Z_2.self)
    print("H(RP^2; Z/2) =", h2.detailDescription, "\n")
}

