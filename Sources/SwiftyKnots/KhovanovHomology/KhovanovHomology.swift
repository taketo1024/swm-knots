//
//  KhovanovHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public extension Link {
    
    private func spliced(_ state: LinkSpliceState) -> Link {
        var L = self.copy()
        for (i, s) in state.enumerated {
            if s == 0 {
                L.spliceA(at: i)
            } else {
                L.spliceB(at: i)
            }
        }
        return L
    }
    
    public var KhovanovChainComplex: CochainComplex<KHBasisElement, 𝐐> {
        typealias C = CochainComplex<KHBasisElement, 𝐐>
        
        let n = crossingNumber
        let allStates = LinkSpliceState.all(n)
        let allBases  = allStates.map{ s -> KHBasis in
            let L = spliced(s)
            return KHBasis.from(state: s, components: L.components)
        }
        
        let basesList = allBases.group( by: { b in b.state.degree } )
            .mapValues{ $0.sorted(by: {(b1, b2) in b1.state < b2.state } ) }
        
        let chain = (0 ... n).map { i -> (C.ChainBasis, C.BoundaryMap) in
            let list = basesList[i]!
            let chainBasis = list.flatMap{ b in b.elements }
            let boundaryMap = C.BoundaryMap { (x: KHBasisElement) -> FreeModule<KHBasisElement, 𝐐> in
                if i < n {
                    let next = basesList[i + 1]!
                    return next.sum { (B: KHBasis) -> FreeModule<KHBasisElement, 𝐐> in
                        let s1 = x.state
                        let s2 = B.state
                        
                        let (i, e) = s1.diff(s2)
                        
                        // 円周の対応を見ておかないといけない
                        
                        if s1.degree < s2.degree { // apply Δ
                            
                            
                        } else {                   // apply m
                            
                        }
                        return .zero
                    }
                } else {
                    return .zero
                }
            }
            return (chainBasis, boundaryMap)
        }
        
        return C(chain: chain)
    }
}
