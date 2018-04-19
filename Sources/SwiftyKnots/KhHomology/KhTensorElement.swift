//
//  KHBasis.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KhTensorElement: BasisElementType, Comparable {
    internal let factors: [KhBasisElement]
    internal let originalLink: Link
    internal let splicedLink: Link
    public let state: LinkSpliceState
    public let shift: Int
    
    internal init(_ factors: [KhBasisElement], _ originalLink: Link, _ splicedLink: Link, _ state: LinkSpliceState, _ shift: Int) {
        self.factors = factors
        self.originalLink = originalLink
        self.splicedLink = splicedLink
        self.state = state
        self.shift = shift
    }
    
    public static func generateBasis(link: Link, state: LinkSpliceState, shift: Int) -> [KhTensorElement] {
        let spliced = link.spliced(by: state)
        let n = spliced.components.count
        
        return (0 ..< n).reduce([[]]) { (res, _) -> [[KhBasisElement]] in
            res.flatMap{ factors -> [[KhBasisElement]] in
                [factors + [.I], factors + [.X]]
            }
        }.map{ factors in KhTensorElement.init(factors, link, spliced, state, shift) }
        .sorted()
    }
    
    public var degree: Int {
        return factors.sum{ e in e.degree } + state.degree + shift
    }
    
    internal typealias E = KhBasisElement
    
    internal func transit<R: EuclideanRing>(_ μ: (E, E) -> [E], _ Δ: (E) -> [(E, E)]) -> FreeModule<KhTensorElement, R> {
        return state.next.sum { (sgn, state) -> FreeModule<KhTensorElement, R> in
            R(from: sgn) * transit(to: state, μ, Δ)
        }
    }
    
    internal func transit<R: EuclideanRing>(to state: LinkSpliceState, _ μ: (E, E) -> [E], _ Δ: (E) -> [(E, E)]) -> FreeModule<KhTensorElement, R> {
        
        let next = originalLink.spliced(by: state) // maybe creating too much copies...
        
        let (c1, c2) = (splicedLink.components, next.components)
        let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
        
        switch (d1.count, d2.count) {
        case (2, 1): // apply μ
            let (i1, i2, j) = (c1.index(of: d1[0])!, c1.index(of: d1[1])!, c2.index(of: d2[0])!)
            let (e1, e2) = (factors[i1], factors[i2])
            
            return μ(e1, e2).sum { e in
                var factor = factors
                factor.remove(at: i2)
                factor.remove(at: i1)
                factor.insert(e, at: j)
                return FreeModule( KhTensorElement(factor, originalLink, next, state, shift) )
            }
            
        case (1, 2): // apply Δ
            let (i, j1, j2) = (c1.index(of: d1[0])!, c2.index(of: d2[0])!, c2.index(of: d2[1])!)
            let e = factors[i]
            
            return Δ(e).sum { (e1, e2) -> FreeModule<KhTensorElement, R> in
                var factor = factors
                factor.remove(at: i)
                factor.insert(e1, at: j1)
                factor.insert(e2, at: j2)
                return FreeModule( KhTensorElement(factor, originalLink, next, state, shift) )
            }
        default: fatalError()
        }
    }
    
    public static func ==(b1: KhTensorElement, b2: KhTensorElement) -> Bool {
        return b1.state == b2.state && b1.factors == b2.factors
    }
    
    public static func <(b1: KhTensorElement, b2: KhTensorElement) -> Bool {
        return (b1.state < b2.state)
            || (b1.state == b2.state
                && (b1.degree < b2.degree
                    || (b1.degree == b2.degree
                        && b1.factors.lexicographicallyPrecedes(b2.factors)
                    )
                )
        )
    }
    
    public var hashValue: Int {
        return factors.reduce(0) { (res, e) in
            res &<< 2 | (e == .I ? 2 : 1)
        }
    }
    
    public var description: String {
        return "(" + factors.map{ "\($0)" }.joined(separator: "⊗") + ")" + Format.sub(state.description)
    }
}
