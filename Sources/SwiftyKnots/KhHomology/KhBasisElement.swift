//
//  KhBasisElement.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KhBasisElement: BasisElementType, Comparable, Codable {
    public let state: KauffmanState
    internal let factors: [E]
    
    public static func generateBasis(state: KauffmanState, power n: Int) -> [KhBasisElement] {
        return (0 ..< n).reduce([[]]) { (res, _) -> [[E]] in
            res.flatMap{ factors -> [[E]] in
                [factors + [.I], factors + [.X]]
            }
            }
            .map{ factors in KhBasisElement.init(state: state, factors: factors) }
            .sorted()
    }
    
    internal init(state: KauffmanState, factors: [E]) {
        self.state = state
        self.factors = factors
    }
    
    public var degree: Int {
        return factors.sum{ e in e.degree } + state.degree
    }
    
    public func stateModified(_ i: Int, _ bit: KauffmanState.Bit?) -> KhBasisElement {
        var s = state
        if let bit = bit {
            s[i] = bit
        } else {
            s.unset(i)
        }
        return KhBasisElement(state: s, factors: factors)
    }
    
    public static func ==(b1: KhBasisElement, b2: KhBasisElement) -> Bool {
        return b1.state == b2.state && b1.factors == b2.factors
    }
    
    public static func <(b1: KhBasisElement, b2: KhBasisElement) -> Bool {
        return (b1.state < b2.state)
            || (b1.state == b2.state && b1.factors.lexicographicallyPrecedes(b2.factors) )
    }
    
    public var hashValue: Int {
        return factors.reduce(0) { (res, e) in
            res &<< 2 | (e == .I ? 2 : 1)
        }
    }
    
    public var description: String {
        return factors.map{ "\($0)" }.joined(separator: "⊗") + Format.sub(state.description)
    }
    
    public enum E: Int, Comparable, Codable {
        case I =  1
        case X = -1
        
        public var degree: Int {
            return rawValue
        }
        
        public static func <(e1: E, e2: E) -> Bool {
            return e1.degree < e2.degree
        }
        
        public var description: String {
            return (self == .I) ? "I" : "X"
        }
    }
}

public extension KhBasisElement {
    public typealias   Product<R: Ring> = (E, E) -> [(E, R)]
    public typealias Coproduct<R: Ring> = (E) -> [(E, E, R)]
    
    public func applied<R: Ring>(_ μ: Product<R>, at: (Int, Int), to j: Int, state: KauffmanState) -> FreeModule<KhBasisElement, R> {
        let (i1, i2) = at
        let (e1, e2) = (factors[i1], factors[i2])
        
        return μ(e1, e2).sum { (e, a) in
            var factors = self.factors
            factors.remove(at: i2)
            factors.remove(at: i1)
            factors.insert(e, at: j)
            let t = KhBasisElement(state: state, factors: factors)
            return FreeModule(t, a)
        }
    }
    
    public func applied<R: Ring>(_ Δ: Coproduct<R>, at i: Int, to: (Int, Int), state: KauffmanState) -> FreeModule<KhBasisElement, R> {
        let (j1, j2) = to
        let e = factors[i]
        
        return Δ(e).sum { (e1, e2, a)  in
            var factors = self.factors
            factors.remove(at: i)
            factors.insert(e1, at: j1)
            factors.insert(e2, at: j2)
            let t = KhBasisElement(state: state, factors: factors)
            return FreeModule(t, a)
        }
    }
    
    // Khovanov's map
    public static func μ<R: Ring>(_ type: R.Type) -> Product<R> {
        return { (e1, e2) in
            switch (e1, e2) {
            case (.I, .I): return [(.I, .identity)]
            case (.I, .X), (.X, .I): return [(.X, .identity)]
            case (.X, .X): return []
            }
        }
    }
    
    public static func Δ<R: Ring>(_ type: R.Type) -> Coproduct<R> {
        return { e in
            switch e {
            case .I: return [(.I, .X, .identity), (.X, .I, .identity)]
            case .X: return [(.X, .X, .identity)]
            }
        }
    }
    
    // Lee's map
    public static func μ_Lee<R: Ring>(_ type: R.Type) -> Product<R> {
        return { (e1, e2) in
            switch (e1, e2) {
            case (.X, .X): return [(.I, .identity)]
            default: return []
            }
        }
    }
    
    public static func Δ_Lee<R: Ring>(_ type: R.Type) -> Coproduct<R> {
        return { e in
            switch e {
            case .X: return [(.I, .I, .identity)]
            default: return []
            }
        }
    }
    
    // Bar-Natan's map
    public static func μ_BN<R: Ring>(_ type: R.Type) -> Product<R> {
        return { (e1, e2) in
            switch (e1, e2) {
            case (.X, .X): return [(.X, .identity)]
            default: return []
            }
        }
    }
    
    public static func Δ_BN<R: Ring>(_ type: R.Type) -> Coproduct<R> {
        return { e in
            switch e {
            case .I: return [(.I, .I, -.identity)]
            default: return []
            }
        }
    }
}
