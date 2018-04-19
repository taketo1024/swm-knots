//
//  KhovanovHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public typealias KhChainComplex<R: EuclideanRing> = CochainComplex<KhTensorElement, R>

public extension KhChainComplex where T == Ascending, A == KhTensorElement, R: EuclideanRing {
    public convenience init(_ L: Link, _ type: R.Type) {
        typealias C = CochainComplex<KhTensorElement, R>
        
        let name = "CKh(\(L.name); \(R.symbol))"
        let (n, n⁺, n⁻) = (L.crossingNumber, L.crossingNumber⁺, L.crossingNumber⁻)
        
        let all = LinkSpliceState.all(n).map { s in
            (s, KhTensorElement.generateBasis(link: L, state: s, shift: n⁺ - 2 * n⁻))
        }
        
        let degList = all.group { (s, _) in s.degree }
        
        let chain = (0 ... n).map { i -> (C.ChainBasis, C.BoundaryMap) in
            let (μ, Δ) = (KhBasisElement.μ, KhBasisElement.Δ)
            
            let list = degList[i]!
            let chainBasis = list.flatMap { $0.1 }
            let boundaryMap = (i < n) ? C.BoundaryMap { x in x.transit(μ, Δ) } : .zero
            
            return (chainBasis, boundaryMap)
        }
        self.init(name: name, chain: chain, offset: -n⁻)
    }
}
