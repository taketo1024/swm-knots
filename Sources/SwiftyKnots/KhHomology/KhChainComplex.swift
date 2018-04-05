//
//  KhovanovHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public typealias KhChainComplex<R: EuclideanRing> = CochainComplex<KhBasisElement, R>

public extension KhChainComplex where T == Ascending, A == KhBasisElement, R: EuclideanRing {
    public convenience init(_ L: Link, _ type: R.Type) {
        typealias C = CochainComplex<KhBasisElement, R>
        
        let name = "CKh(\(L.name); \(R.symbol))"
        let (n, n⁺, n⁻) = (L.crossingNumber, L.crossingNumber⁺, L.crossingNumber⁻)
        
        let all = LinkSpliceState.all(n).map { s in
            KhChainSummand(link: L, state: s, shift: n⁺ - 2 * n⁻)
        }
        
        let degList = all.group(by: { C in C.state.degree })
        
        let chain = (0 ... n).map { i -> (C.ChainBasis, C.BoundaryMap) in
            let list = degList[i]!
            let chainBasis = list.flatMap{ C in C.basis }
            let boundaryMap = (i < n) ? C.BoundaryMap { x in x.transit(μ, Δ) } : .zero
            return (chainBasis, boundaryMap)
        }
        self.init(name: name, chain: chain, offset: -n⁻)
    }
}

private func μ(_ e1: KhBasisElement.E, _ e2: KhBasisElement.E) -> [KhBasisElement.E] {
    switch (e1, e2) {
    case (.I, .I): return [.I]
    case (.I, .X), (.X, .I): return [.X]
    case (.X, .X): return []
    }
}

private func Δ(_ e: KhBasisElement.E) -> [(KhBasisElement.E, KhBasisElement.E)] {
    switch e {
    case .I: return [(.I, .X), (.X, .I)]
    case .X: return [(.X, .X)]
    }
}
