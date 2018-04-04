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
            KhChainSummand(link: L, state: s, shift: n⁺ - 2 * n⁻ + s.degree)
        }
        
        let stTable = Dictionary(pairs: all.map{ C in (C.state, C) })
        let degList = all.group(by: { C in C.state.degree })
        
        let chain = (0 ... n).map { i -> (C.ChainBasis, C.BoundaryMap) in
            let list = degList[i]!
            let chainBasis = list.flatMap{ C in C.basis }
            let boundaryMap = (i < n) ? C.BoundaryMap { (x: KhTensorElement) -> C.Chain in
                let C1 = stTable[x.state]!
                let next = x.state.next
                return next.sum { (sgn, st) in
                    let C2 = stTable[st]!
                    return R(from: sgn) * map(x, from: C1, to: C2)
                }
            } : .zero
            
            return (chainBasis, boundaryMap)
        }
        self.init(name: name, chain: chain, offset: -n⁻)
    }
    
}

private func map<R: EuclideanRing>(_ x: KhTensorElement, from: KhChainSummand, to: KhChainSummand) -> FreeModule<KhTensorElement, R> {
    typealias E = KhTensorElement.E
    
    let (c1, c2) = (from.components, to.components)
    let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
    
    switch (d1.count, d2.count) {
    case (2, 1): // apply μ
        let (i1, i2, j) = (c1.index(of: d1[0])!, c1.index(of: d1[1])!, c2.index(of: d2[0])!)
        let (e1, e2) = (x.factors[i1], x.factors[i2])
        
        assert(i1 < i2)
        
        if let e = E.μ(e1, e2) {
            var factor = x.factors
            factor.remove(at: i2)
            factor.remove(at: i1)
            factor.insert(e, at: j)
            return FreeModule( KhTensorElement(factor, to.state, to.shift) )
        } else {
            return .zero
        }
        
    case (1, 2): // apply Δ
        let (i, j1, j2) = (c1.index(of: d1[0])!, c2.index(of: d2[0])!, c2.index(of: d2[1])!)
        let e = x.factors[i]
        
        assert(j1 < j2)
        
        return E.Δ(e).sum { (e1, e2) -> FreeModule<KhTensorElement, R> in
            var factor = x.factors
            factor.remove(at: i)
            factor.insert(e1, at: j1)
            factor.insert(e2, at: j2)
            return FreeModule( KhTensorElement(factor, to.state, to.shift) )
        }
    default:
        fatalError()
    }
}
