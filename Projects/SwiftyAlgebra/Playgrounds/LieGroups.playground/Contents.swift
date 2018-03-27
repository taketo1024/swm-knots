//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias GL  = GeneralLinearGroup
typealias SL  = SpecialLinearGroup
typealias O   = OrthogonalGroup
typealias SO  = SpecialOrthogonalGroup
typealias U   = UnitaryGroup
typealias SU  = SpecialUnitaryGroup
typealias Sp  = SymplecticGroup
typealias USp = UnitarySymplecticGroup

typealias gl  = GeneralLinearLieAlgebra
typealias sl  = SpecialLinearLieAlgebra
typealias o   = OrthogonalLieAlgebra
typealias u   = UnitaryLieAlgebra
typealias su  = SpecialUnitaryLieAlgebra
typealias sp  = SymplecticLieAlgebra
typealias usp = UnitarySymplecticLieAlgebra

typealias n = _2

let i = 𝐂.imaginaryUnit
let X = gl<n, 𝐂>(0, 2 + i, -2 + i, 0)
let g = exp(X)

print(X.detailDescription, "\n")
print(g.detailDescription, "\n")
print(U<n>.contains(g))
