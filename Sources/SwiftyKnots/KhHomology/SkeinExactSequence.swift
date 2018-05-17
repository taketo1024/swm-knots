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
    
    public func skeinExactSequence<R>(_ type: R.Type, atCrossing i: Int? = nil, reduced: Bool = false, solved: Bool = true) -> CohomologyExactSequence<R> {
        typealias C = CochainComplex<KhTensorElement, R>
        typealias M = CochainMap<KhTensorElement, KhTensorElement, R>
        
        let n = crossingNumber - 1
        let L = (i == nil || i! == n)
            ? self
            : Link(name: name, crossings: crossings.moved(elementAt: i!, to: n))
        
        let (L0, L1) = L.splicedPair(at: n)

        //                 i      j
        //  0 --> c1{1,1} ---> c ---> c0 --> 0 (exact)
        //
        
        let (c1, c, c0) = (L1.KhChainComplex(R.self, reduced: reduced, normalized: false, shifted: (1, 1)),
                           L .KhChainComplex(R.self, reduced: reduced, normalized: false),
                           L0.KhChainComplex(R.self, reduced: reduced, normalized: false))
        
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
        
        print( L.KhHomology(c) , "\n")
        print(L0.KhHomology(c0), "\n")
        print(L1.KhHomology(c1), "\n")

        let S = CochainComplexSES(c1, i, c, j, c0, d)
        var H = CohomologyExactSequence(S)
        
        if solved {
            H.fill(columns: 0, 1, 2)
            H.solve()
        }
        
        return H
    }
}
