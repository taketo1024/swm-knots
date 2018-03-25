//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

typealias GL = GeneralLinearGroup
typealias SL = SpecialLinearGroup
typealias O  = OrthogonalGroup
typealias U  = UnitaryGroup

typealias gl = GeneralLinearLieAlgebra
typealias sl = SpecialLinearLieAlgebra

typealias n = _2

let i = 𝐂.imaginaryUnit
let X = gl<n, CC
let g = exp(X)

print(X.detailDescription, "\n")
print(g.detailDescription, "\n")
print(U<n>.contains(g))

