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
        typealias M = FreeModule<R>
        let (A, inBases, outBases) = toMatrix()
        let (kerVecs, imVecs) = kerIm(A)
        
        let kers = kerVecs.map{(v) in (0 ..< A.cols).reduce(M.zero){(res, i) in res + v[i] * M(inBases[i])} }
        return (kers, [])
    }
}

//let (kers, ims) = f.describe()
print(kers)
