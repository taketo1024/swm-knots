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
    let Δ = V.simplex(0, 1, 2, 3).allSubsimplices()
    let H = SimplicialComplex(Δ).ZHomology()
    print("H(D^3; Z) =", H.detailDescription, "\n")
}

// ∂Δ^3 = S^2
do {
    let dΔ = V.simplex(0, 1, 2, 3).skeleton(2)
    let H = SimplicialComplex(dΔ).ZHomology()
    print("H(S^2; Z) =", H.detailDescription, "\n")
}

// T^2 = S^1 x S^1
do {
    let faces = (0 ..< 3).flatMap{ i in
        (0 ..< 3).flatMap { j -> [Simplex] in
            let v0 = i * 3 + j
            let v1 = v0 + ((j < 2) ? 1 : -2)
            let v2 = (v0 + 3) % 9
            let v3 = v2 + ((j < 2) ? 1 : -2)
            return [V.simplex(v0, v1, v2), V.simplex(v1, v2, v3)]
        }
    }
    let H = SimplicialComplex(faces, generate: true).ZHomology()
    print("H(T^2; Z) =", H.detailDescription, "\n")
}

// RP^2
do {
    let s = V.simplex
    let faces = [s(0,1,3),s(1,4,3),s(1,2,4),s(4,2,0),s(4,0,5),s(0,1,5),s(1,2,5),s(2,3,5),s(0,3,2),s(3,4,5)]
    let H = SimplicialComplex(faces, generate: true).ZHomology()
    print("H(RP^2; Z) =", H.detailDescription, "\n")
}

// Klein-Bottle cellular
do {
    let bases: [[String]] = [["e0"], ["e10", "e11"], ["e2"]]
    let table: [[Z]] = [[0], [0, 0], [2, 0]]
    let H = Homology(ChainComplex(chainBases: bases, boundaryMapTable: table))
    print("H(Kl; Z) =", H.detailDescription, "\n")
}

// Mobius band
do {
    let s = V.simplex
    let faces = [s(0,1,3), s(1,3,4),s(1,2,4),s(2,4,5),s(2,3,5),s(3,5,0)]
    let H = SimplicialComplex(faces, generate: true).ZHomology()
    print("H(M; Z) =", H.detailDescription, "\n")
}
