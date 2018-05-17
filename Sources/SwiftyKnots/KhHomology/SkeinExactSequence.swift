//
//  SkeinExactSequence.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/17.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension Link {
    
    // MEMO currently supports only unnormalized degrees.
    
    public func skeinExactSequence<R>(_ type: R.Type, reduced r: Bool = false) -> CohomologyExactSequence<R> {
        typealias C = CochainComplex<KhTensorElement, R>
        typealias M = CochainMap<KhTensorElement, KhTensorElement, R>
        
        let L = self
        let n = L.crossingNumber - 1
        let (L0, L1) = L.splicedPair(at: n)

        //                 i      j
        //  0 --> c1{1,1} ---> c ---> c0 --> 0 (exact)
        //
        
        let (c1, c, c0) = (L1.KhChainComplex(R.self, reduced: r, normalized: false, shifted: (1, 1)),
                           L .KhChainComplex(R.self, reduced: r, normalized: false),
                           L0.KhChainComplex(R.self, reduced: r, normalized: false))
        
        let i = M { (e: KhTensorElement) in
            C.Chain(e.stateModified(n, .I))
        }
        
        let j = M { (e: KhTensorElement) in
            e.state[n] == .O ? C.Chain(e.stateModified(n, nil)) : .zero
        }
        
        let d = M(degree: 1) { (e0: KhTensorElement) in
            let e = e0.stateModified(n, .O)
            let de: C.Chain = L.KhCube.d(e)
            return de.map { (e, a) -> (KhTensorElement, R) in
                e.state[n] == .I ? (e.stateModified(n, nil), a) : (e, .zero)
            }
        }
        
        print(L1.KhHomology(c1), "\n")
        print( L.KhHomology(c) , "\n")
        print(L0.KhHomology(c0), "\n")
        
        let S = CochainComplexSES(c1, i, c, j, c0, d)
        let H = CohomologyExactSequence(S)
        
        return H
    }
}
