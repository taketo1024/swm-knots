//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

let V = VertexSet(number: 10)

/*
// Δ^3 = D^3
let Δ = V.simplex(0, 1, 2, 3).allSubsimplices()
let H1 = SimplicialComplex(Δ).ZHomology()

// ∂Δ^3 = S^2
let dΔ = V.simplex(0, 1, 2, 3).skeleton(2)
let H2 = SimplicialComplex(dΔ).ZHomology()
 */

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
print(H3)

// RP^2
//let s = V.simplex
//let H4 = SimplicialComplex([s(1,3,4), s(1,4,5), s(1,5,2), s(3,4,2), s(2,4,6), s(4,5,6), s(6,5,3),s(5,2,3), s(1,2,6), s(1,6,3)], generate: true).ZHomology()

//typealias M = FreeModule<String, Z>
//typealias F = FreeModuleHom<String, Z>
//
//let C = ChainComplex<String, Z>(
//    (["e0"], F.zero),
//    (["e10", "e11"], F.zero),
//    (["e2"], F(inBasis :["e2"],
//               outBasis:["e10", "e11"],
//               matrix: Matrix<Z,_2,_1>(2, 0)))
//).homology()
//
//C.chainComplex.dim
