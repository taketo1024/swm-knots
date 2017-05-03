//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

typealias M = FreeModule<Z>

let a = M("a")
let b = M("b")
let c = M("c")
let d = M("d")
let zero = M.zero

let map: [FreeModule<Z> : FreeModule<Z>] =
    [a: a + b,
     b: b + c,
     c: c + d,
     d: d + a]

let f = FreeModuleHom<Z>(map)

let (ker, im) = f.kerIm()
print(ker)
print(im)
