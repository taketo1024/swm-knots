//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

typealias M = FreeModule<String, Z>

let a = M("a")
let b = M("b")
let c = M("c")
let d = M("d")
let zero = M.zero

let map: [String : M] =
    ["a" : a + b,
     "b" : b + c,
     "c" : c + d,
     "d" : d + a]

let f = FreeModuleHom<String, Z>(map)
let x = f.appliedTo(a + 2 * b)
let k = f.kernelBases

print(k)