//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias M = FreeModule<String, 𝐙>

let domain   = ["a", "b", "c", "d"]
let codomain = ["x", "y", "z"]
let matrix = Matrix<_3, _4, 𝐙>(
    1, 2, 1,  1,
    2, 0, 2, -1,
    1, 3, 3,  2
)

let f = FreeModuleHom(from: domain, to: codomain, matrix: matrix)

let a = M("a")
let b = M("b")
let x = a + 2 * b
let y = f.appliedTo(x) // (x + 2y + z) + 2(2x + 3z)

y == M(["x" : 5, "y" : 2, "z" : 7])
