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
let f = FreeModuleHom<Z>([a: a + b, b: (2*a) + (2*b), c: a - b, d: zero])

let (kers, _) = f.describe()
print("kers: \(kers)")

let ker = kers[0]
f.appliedTo(ker)


extension FreeModuleHom where R: EuclideanRing {
    public func toMatrix() -> (matrix: TypeLooseMatrix<R>, inBases: [String], outBases: [String]) {
        let inBases = Array(mapping.keys).sorted()
        let outBases = Array(Set(mapping.values.flatMap { $0.bases })).sorted()
        let A = TypeLooseMatrix<R>(outBases.count, inBases.count) { (i, j) -> R in
            let from = inBases[j]
            let to  = outBases[i]
            return mapping[from]?.coeff(to) ?? 0
        }
        return (A, inBases, outBases)
    }
    
    public func describe() -> (Ker: [FreeModule<R>], Im: [FreeModule<R>]) {
        let (A, inBases, outBases) = toMatrix()
        let (B, P, Q) = eliminateMatrix(A) // B = Q^-1 A P
        
        let diag = (0 ..< min(A.rows, A.cols)).map{ A[$0, $0] }
        let imDim = diag.filter({$0 != 0}).count
        let kerDim = A.cols - imDim
        let kers = (A.cols - kerDim ..< A.cols).map { j -> FreeModule<R> in
            (0 ..< P.rows).reduce(FreeModule<R>.zero){ (res, i) -> FreeModule<R> in res + P[i, j] * M(inBases[i])}
        }
        return (kers, [])
    }
}