//
//  KhovanovHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public extension Link {
    public func KhChainComplex<R: EuclideanRing>(_ type: R.Type) -> CochainComplex<KhTensorElement, R> {
        typealias C = CochainComplex<KhTensorElement, R>
        
        let name = "CKh(\(self.name); \(R.symbol))"
        let (n, n⁺, n⁻) = (crossingNumber, crossingNumber⁺, crossingNumber⁻)
        
        let all = LinkSpliceState.all(n).map { s in
            (s, KhTensorElement.generateBasis(link: self, state: s, shift: n⁺ - 2 * n⁻))
        }
        
        let degList = all.group { (s, _) in s.degree }
        
        let chain = (0 ... n).map { i -> (C.ChainBasis, C.BoundaryMap) in
            let (μ, Δ) = (KhBasisElement.μ, KhBasisElement.Δ)
            
            let list = degList[i]!
            let chainBasis = list.flatMap { $0.1 }
            let boundaryMap = (i < n) ? C.BoundaryMap { x in x.transit(μ, Δ) } : .zero
            
            return (chainBasis, boundaryMap)
        }
        
        return CochainComplex(name: name, chain: chain, offset: -n⁻)
    }
}
