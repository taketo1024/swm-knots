//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

let V = VertexSet(number: 10)

// Δ^3 = D^3
do {
    let C = SimplicialComplex.ball(dim: 3)
    let H = Homology(C, Z.self)
    print("H(D^3; Z) =", H.detailDescription, "\n")
}

// ∂Δ^3 = S^2
do {
    let C = SimplicialComplex.sphere(dim: 2)
    let H = Homology(C, Z.self)
    print("H(S^2; Z) =", H.detailDescription, "\n")
}

// T^2 = S^1 x S^1
do {
    let C = SimplicialComplex.torus(dim: 2)
    let H = Homology(C, Z.self)
    print("H(T^2; Z) =", H.detailDescription, "\n")
}

// RP^2
do {
    let s = V.simplex(_:)
    let faces = [s(0,1,3),s(1,4,3),s(1,2,4),s(4,2,0),s(4,0,5),s(0,1,5),s(1,2,5),s(2,3,5),s(0,3,2),s(3,4,5)]
    let C = SimplicialComplex(V, faces, generate: true)
    let H = Homology(C, Z.self)
    print("H(RP^2; Z) =", H.detailDescription, "\n")
}

// Klein-Bottle cellular
do {
    let C = ChainComplex(
        (["e0"], [0]),
        (["e10", "e11"], [0, 0]),
        (["e2"], [2, 0])
    )
    let H = Homology(C)
    print("H(Kl; Z) =", H.detailDescription, "\n")
}

// Mobius band
do {
    let s = V.simplex(_:)
    let faces = [s(0,1,3), s(1,3,4),s(1,2,4),s(2,4,5),s(2,3,5),s(3,5,0)]
    let C = SimplicialComplex(V, faces, generate: true)
    let H = Homology(C, Z.self)
    print("H(M; Z) =", H.detailDescription, "\n")
}

// other coeffs
do {
    let s = V.simplex(_:)
    let faces = [s(0,1,3),s(1,4,3),s(1,2,4),s(4,2,0),s(4,0,5),s(0,1,5),s(1,2,5),s(2,3,5),s(0,3,2),s(3,4,5)]
    let C = SimplicialComplex(V, faces, generate: true)
    
    let H = Homology(C, Z_2.self)
    print("H(RP^2; Z/2) =", H.detailDescription, "\n")
    
    let H2 = Homology(C, Q.self)
    print("H(RP^2; Q) =", H2.detailDescription, "\n")
    
    let cH = Cohomology(C, Z.self)
    print("cH(RP^2; Z) =", cH.detailDescription, "\n")
}
