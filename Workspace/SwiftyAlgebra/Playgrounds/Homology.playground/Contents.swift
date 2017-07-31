//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// D^3 = Δ^3
do {
    let D3 = SimplicialComplex.ball(dim: 3)
    let H = Homology(D3, Z.self)
    print("H(D^3; Z) =", H.debugDescription, "\n")
}

// S^2 = ∂Δ^3
do {
    let S2 = SimplicialComplex.sphere(dim: 2)
    let H = Homology(S2, Z.self)
    print("H(S^2; Z) =", H.debugDescription, "\n")
}

// (D^3, S^2) relative
do {
    let D3 = SimplicialComplex.ball(dim: 3)
    let S2 = D3.skeleton(2)
    let H = Homology(D3, S2, Z.self)
    print("H(D^3, S^2; Z) =", H.debugDescription, "\n")
}

// T^2 = S^1 x S^1
do {
    let T2 = SimplicialComplex.torus(dim: 2)
    let H = Homology(T2, Z.self)
    print("H(T^2; Z) =", H.debugDescription, "\n")
}

// RP^2
do {
    let RP2 = SimplicialComplex.realProjectiveSpace(dim: 2)
    let H1 = Homology(RP2, Z.self)
    print("H(RP^2; Z) =", H1.debugDescription, "\n")
    
    let H2 = Homology(RP2, Z_2.self)
    print("H(RP^2; Z/2) =", H2.debugDescription, "\n")
    
    let cH = Cohomology(RP2, Z.self)
    print("cH(RP^2; Z) =", cH.debugDescription, "\n")
}
