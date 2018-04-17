//
//  KHBasis.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KhChainSummand: Equatable, CustomStringConvertible {
    public let state: LinkSpliceState
    public let basis: [KhBasisElement]
    public let shift: Int
    
    public init(link L: Link, state: LinkSpliceState, shift: Int = 0) {
        self.state = state
        self.basis = KhBasisElement.generate(L, state, shift)
        self.shift = shift
    }
    
    public static func ==(B1: KhChainSummand, B2: KhChainSummand) -> Bool {
        return B1.basis == B2.basis
    }
    
    public var description: String {
        let n = basis.anyElement?.tensorFactors.count ?? 0
        let s = shift + state.degree
        return Format.term(1, "V", n) + "{\(s)}" + Format.sub(state.description)
    }
}

public struct KhBasisElement: BasisElementType, Comparable {
    internal let tensorFactors: [E]
    internal let originalLink: Link
    internal let splicedLink: Link
    public let state: LinkSpliceState
    public let shift: Int
    
    internal init(_ tensorFactors: [E], _ originalLink: Link, _ splicedLink: Link, _ state: LinkSpliceState, _ shift: Int) {
        self.tensorFactors = tensorFactors
        self.originalLink = originalLink
        self.splicedLink = splicedLink
        self.state = state
        self.shift = shift
    }
    
    public static func generate(_ link: Link, _ state: LinkSpliceState, _ shift: Int) -> [KhBasisElement] {
        let spliced = link.spliced(by: state)
        let n = spliced.components.count
        
        return (0 ..< n).reduce([[]]) { (res, _) -> [[E]] in
            res.flatMap{ factors -> [[E]] in
                [factors + [.I], factors + [.X]]
            }
        }.map{ factors in KhBasisElement.init(factors, link, spliced, state, shift) }
        .sorted()
    }
    
    public var degree: Int {
        return tensorFactors.sum{ e in e.degree } + state.degree + shift
    }
    
    public func transit<R: EuclideanRing>(_ μ: (E, E) -> [E], _ Δ: (E) -> [(E, E)]) -> FreeModule<KhBasisElement, R> {
        return state.next.sum { (sgn, state) -> FreeModule<KhBasisElement, R> in
            R(from: sgn) * transit(to: state, μ, Δ)
        }
    }
    
    public func transit<R: EuclideanRing>(to state: LinkSpliceState, _ μ: (E, E) -> [E], _ Δ: (E) -> [(E, E)]) -> FreeModule<KhBasisElement, R> {
        
        let next = originalLink.spliced(by: state) // maybe creating too much copies...
        
        let (c1, c2) = (splicedLink.components, next.components)
        let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
        
        switch (d1.count, d2.count) {
        case (2, 1): // apply μ
            let (i1, i2, j) = (c1.index(of: d1[0])!, c1.index(of: d1[1])!, c2.index(of: d2[0])!)
            let (e1, e2) = (tensorFactors[i1], tensorFactors[i2])
            
            return μ(e1, e2).sum { e in
                var factor = tensorFactors
                factor.remove(at: i2)
                factor.remove(at: i1)
                factor.insert(e, at: j)
                return FreeModule( KhBasisElement(factor, originalLink, next, state, shift) )
            }
            
        case (1, 2): // apply Δ
            let (i, j1, j2) = (c1.index(of: d1[0])!, c2.index(of: d2[0])!, c2.index(of: d2[1])!)
            let e = tensorFactors[i]
            
            return Δ(e).sum { (e1, e2) -> FreeModule<KhBasisElement, R> in
                var factor = tensorFactors
                factor.remove(at: i)
                factor.insert(e1, at: j1)
                factor.insert(e2, at: j2)
                return FreeModule( KhBasisElement(factor, originalLink, next, state, shift) )
            }
        default: fatalError()
        }
    }
    
    public static func ==(b1: KhBasisElement, b2: KhBasisElement) -> Bool {
        return b1.state == b2.state && b1.tensorFactors == b2.tensorFactors
    }
    
    public static func <(b1: KhBasisElement, b2: KhBasisElement) -> Bool {
        return (b1.state < b2.state)
            || (b1.state == b2.state
                && (b1.degree < b2.degree
                    || (b1.degree == b2.degree
                        && b1.tensorFactors.lexicographicallyPrecedes(b2.tensorFactors)
                    )
                )
        )
    }
    
    public var hashValue: Int {
        return tensorFactors.reduce(0) { (res, e) in
            res &<< 2 | (e == .I ? 2 : 1)
        }
    }
    
    public var description: String {
        return "(" + tensorFactors.map{ "\($0)" }.joined(separator: "⊗") + ")" + Format.sub(state.description)
    }
    
    public enum E: Equatable, Comparable {
        case I
        case X
        
        public var degree: Int {
            switch self {
            case .I: return +1
            case .X: return -1
            }
        }
        
        public static func <(e1: E, e2: E) -> Bool {
            return e1.degree < e2.degree
        }
    }
}
