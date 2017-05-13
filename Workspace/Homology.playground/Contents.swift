//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

let V = VertexSet(number: 10)

// Δ^3 = D^3
let Δ = V.simplex(0, 1, 2, 3).allSubsimplices()
let H1 = SimplicialComplex(Δ).ZHomology()
print("H(D^3; Z) =", H1.detailDescription)
print()

// ∂Δ^3 = S^2
let dΔ = V.simplex(0, 1, 2, 3).skeleton(2)
let H2 = SimplicialComplex(dΔ).ZHomology()
print("H(S^2; Z) =", H2.detailDescription)
print()

// T^2 = S^1 x S^1
let faces = (0 ..< 3).flatMap{ i in
    (0 ..< 3).flatMap { j -> [Simplex] in
        let v0 = i * 3 + j
        let v1 = v0 + ((j < 2) ? 1 : -2)
        let v2 = (v0 + 3) % 9
        let v3 = v2 + ((j < 2) ? 1 : -2)
        return [V.simplex(v0, v1, v2), V.simplex(v1, v2, v3)]
    }
}
let H3 = SimplicialComplex(faces, generate: true).ZHomology()
print("H(T^2; Z) =", H3.detailDescription)
print()
 
// RP^2
let s = V.simplex
let H4 = SimplicialComplex([s(0,1,3),s(1,4,3),s(1,2,4),s(4,2,0),s(4,0,5),s(0,1,5),s(1,2,5),s(2,3,5),s(0,3,2),s(3,4,5)], generate: true).ZHomology()
print("H(RP^2; Z) =", H4.detailDescription)
