//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra
import SwiftyTopology

// Homology or Cohomology

typealias H = Homology
//typealias H = Cohomology

// Coeff Ring

typealias R = 𝐙
//typealias R = 𝐙₂
//typealias R = 𝐐

// D^3 = Δ^3
do {
    let D3 = SimplicialComplex.ball(dim: 3)
    let h  = H(D3, R.self)
    print(h.detailDescription, "\n")
}

// S^2 = ∂Δ^3
do {
    let S2 = SimplicialComplex.sphere(dim: 2)
    let h  = H(S2, R.self)
    print(h.detailDescription, "\n")
}

// (D^3, S^2) relative
do {
    let D3 = SimplicialComplex.ball(dim: 3)
    let S2 = D3.skeleton(2)
    let h  = H(D3, S2, R.self)
    print(h.detailDescription, "\n")
}

// T^2 = S^1 x S^1
do {
    let T2 = SimplicialComplex.torus(dim: 2)
    let h  = H(T2, R.self)
    print(h.detailDescription, "\n")
}

// RP^2
do {
    let RP2 = SimplicialComplex.realProjectiveSpace(dim: 2)
    let h   = H(RP2, R.self)
    print(h.detailDescription, "\n")
}
