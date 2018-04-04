//
//  KhovanovHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public typealias KhChainComplex<R: EuclideanRing> = CochainComplex<KhTensorElement, R>

public extension KhChainComplex where A == KhTensorElement, R: EuclideanRing {
    public convenience init(_ L: Link) {
        typealias C = CochainComplex<KhTensorElement, R>
        
        let name = "CKh"
        let n = L.crossingNumber
        
        let all = LinkSpliceState.all(n).map { s in
            KhChainSummand(link: L, state: s)
        }
        
        let stTable = Dictionary(pairs: all.map{ C in (C.state, C) })
        let degList = all.group(by: { C in C.state.degree })
        
        let chain = (0 ... n).map { i -> (C.ChainBasis, C.BoundaryMap) in
            let list = degList[i]!
            let chainBasis = list.flatMap{ C in C.basis }
            let boundaryMap = (i < n) ? C.BoundaryMap { (x: KhTensorElement) -> C.Chain in
                let C1 = stTable[x.state]!
                let next = degList[i + 1]!
                return next.sum { C2 in map(x, from: C1, to: C2) }
            } : .zero
            return (chainBasis, boundaryMap)
        }
        self.init(name: name, chain: chain)
    }
    
}

private func map<R: EuclideanRing>(_ x: KhTensorElement, from: KhChainSummand, to: KhChainSummand) -> FreeModule<KhTensorElement, R> {
    fatalError("TODO")
}
