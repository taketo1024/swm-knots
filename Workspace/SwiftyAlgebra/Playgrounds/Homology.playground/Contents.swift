//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

let V = VertexSet(number: 10)
let s = { (indices: Int...) -> Simplex in Simplex(V, indices) }

// D^3 = Δ^3
do {
    let D3 = SimplicialComplex.ball(dim: 3)
    let H = Homology(D3, Z.self)
    print("H(D^3; Z) =", H.detailDescription, "\n")
}

// S^2 = ∂Δ^3
do {
    let S2 = SimplicialComplex.sphere(dim: 2)
    let H = Homology(S2, Z.self)
    print("H(S^2; Z) =", H.detailDescription, "\n")
}

// (D^3, S^2) relative
do {
    let D3 = SimplicialComplex.ball(dim: 3)
    let S2 = D3.skeleton(2)
    let H = Homology(D3, S2, Z.self)
    print("H(D^3, S^2; Z) =", H.detailDescription, "\n")
}

// T^2 = S^1 x S^1
do {
    let T2 = SimplicialComplex.torus(dim: 2)
    let H = Homology(T2, Z.self)
    print("H(T^2; Z) =", H.detailDescription, "\n")
}

// RP^2
do {
    let faces = [s(0,1,3),s(1,4,3),s(1,2,4),s(4,2,0),s(4,0,5),s(0,1,5),s(1,2,5),s(2,3,5),s(0,3,2),s(3,4,5)]
    let RP2 = SimplicialComplex(V, faces, generate: true)
    let H = Homology(RP2, Z.self)
    print("H(RP^2; Z) =", H.detailDescription, "\n")
}

// Mobius band
do {
    let faces = [s(0,1,3), s(1,3,4),s(1,2,4),s(2,4,5),s(2,3,5),s(3,5,0)]
    let Mob = SimplicialComplex(V, faces, generate: true)
    let H = Homology(Mob, Z.self)
    print("H(Mob; Z) =", H.detailDescription, "\n")
}

// other coeffs
do {
    let faces = [s(0,1,3),s(1,4,3),s(1,2,4),s(4,2,0),s(4,0,5),s(0,1,5),s(1,2,5),s(2,3,5),s(0,3,2),s(3,4,5)]
    let RP2 = SimplicialComplex(V, faces, generate: true)
    
    let H = Homology(RP2, Z_2.self)
    print("H(RP^2; Z/2) =", H.detailDescription, "\n")
    
    let H2 = Homology(RP2, Q.self)
    print("H(RP^2; Q) =", H2.detailDescription, "\n")
    
    let cH = Cohomology(RP2, Z.self)
    print("cH(RP^2; Z) =", cH.detailDescription, "\n")
}
