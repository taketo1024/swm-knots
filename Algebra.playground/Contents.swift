//: Playground - noun: a place where people can play

import Foundation

typealias _2 = TPInt_2
typealias _3 = TPInt_3
typealias _4 = TPInt_4

let a = Matrix<Z, _3, _2>(2, 3, 1, 4, 2, 1)
let b = Matrix<Z, _2, _3>(3, 1, 2, 2, 4, 2)
let c = a * b

let S = SymGroup<_4>.all
print(S)
