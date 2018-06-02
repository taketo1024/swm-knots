//
//  Homology.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/02.
//

import Foundation
import SwiftyMath

public extension ChainComplexN {
    internal func isFreeToFree(_ I: IntList) -> Bool {
        if let from = base[I], from.isFree,
            let to = base[I + dDegree], to.isFree {
            return true
        } else {
            return false
        }
    }
    
    internal func kernel(_ I: IntList) -> Matrix<R>? {
        guard isFreeToFree(I), let A = dMatrix(I) else {
            return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelMatrix
    }
    
    internal func kernelTransition(_ I: IntList) -> Matrix<R>? {
        guard isFreeToFree(I), let A = dMatrix(I) else {
            return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelTransitionMatrix
    }
    
    internal func image(_ I: IntList) -> Matrix<R>? {
        guard isFreeToFree(I), let A = dMatrix(I) else {
            return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.imageMatrix
    }
    
    public func homology(_ I: IntList) -> ModuleObject<A, R>? {
        // case: indeterminable
        if self[I] == nil {
            return nil
        }
        
        // case: obviously isom
        if  let Ain = dMatrix(I - dDegree), Ain.isZero,
            let Aout = dMatrix(I), Aout.isZero {
            return self[I]
        }
        
        // case: obviously zero
        if let Z = kernel(I), Z.isZero {
            return .zeroModule
        }
        
        // case: free
        if isFreeToFree(I) {
            let basis = self[I]!.generators
            let Z = kernel(I)!
            let T = kernelTransition(I)!
            let B = image(I - dDegree)!
                
            let res = ModuleObject(
                basis: basis,
                generatingMatrix: Z,
                transitionMatrix: T,
                relationMatrix: T * B
            )
            return !res.isZero ? res : .zeroModule
        }
        
        if dSplits(I) && dSplits(I - dDegree) {
            // case: splits as 𝐙, 𝐙₂ summands
            if R.self == 𝐙.self && self[I]!.torsionCoeffs.forAll({ $0 as! 𝐙 == 2 }) {
                let free = (freePart.homology(I)! as! ModuleObject<A, 𝐙>)
                let tor = (self as! ChainComplexN<n, A, 𝐙>).order2torsionPart.homology(I)!
                let sum = free ⊕ tor.asIntegerQuotients
                
                return .some( sum as! ModuleObject<A, R> )
            } else {
                // TODO
                print(I, ": split")
                describeMap(I)
                return nil
            }
        }
        
        return nil
    }
    
    internal func dSplits(_ I: IntList) -> Bool {
        guard let from = self[I],
            let to = self[I + dDegree],
            let A = dMatrix(I) else {
                return false
        }
        
        // MEMO summands are assumed to be ordered as:
        // (R/d_0 ⊕ ... ⊕ R/d_k) ⊕ R^r
        
        func t(_ s: ModuleObject<A, R>) -> [(R, Int)] {
            return s.summands.reduce([]) { (res, s) in
                if let l = res.last, l.0 == s.divisor {
                    return res[0 ..< res.count - 1] + [(l.0, l.1 + 1)]
                } else {
                    return res + [(s.divisor, 1)]
                }
            }
        }
        
        let t0 = t(from)
        let t1 = t(to)
        
        let blocks = A.blocks(rowSizes: t1.map{ $0.1 }, colSizes: t0.map{ $0.1 })
        return blocks.enumerated().forAll { (i, Bs) in
            Bs.enumerated().forAll { (j, B) in
                return (t0[j].0 == t1[i].0) || B.isZero
            }
        }
    }
    
    public func homology(name: String? = nil) -> ModuleGridN<n, A, R> {
        return ModuleGridN(
            name: name ?? "H(\(base.name))",
            list: base.mDegrees.map{ I in (I, homology(I)) },
            default: base.defaultObject
        )
    }
    
    public var isExact: Bool {
        return homology().isZero
    }
}

public extension ChainComplexN where n == _1 {
    public func homology(_ i: Int) -> ModuleObject<A, R>? {
        return homology(IntList(i))
    }
}

public extension ChainComplexN where n == _2 {
    public func homology(_ i: Int, _ j: Int) -> ModuleObject<A, R>? {
        return homology(IntList(i, j))
    }
}
