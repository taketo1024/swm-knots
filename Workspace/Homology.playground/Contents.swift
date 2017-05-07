//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

let V = VertexSet(number: 10)
let s = V.simplex(0, 1, 2, 3)

let SC = SimplicialComplex(s.allSubsimplices())
let CC: ChainComplex<Simplex, Z> = SC.chainComplex()

let z = CC.boundaries(0)
print(z)
