//
//  KhBasisElement.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KhBasisElement: BasisElementType, Comparable, Codable {
    public let state: IntList
    internal let factors: [E]
    
    internal init(state: IntList, factors: [E]) {
        self.state = state
        self.factors = factors
    }
    
    public var degree: Int {
        return factors.sum{ e in e.degree } + state.components.count{ $0 == 1 }
    }
    
    /*
    public func stateModified(_ i: Int, _ bit: KauffmanState.Bit?) -> KhBasisElement {
        var s = state
        if let bit = bit {
            s[i] = bit
        } else {
            s.unset(i)
        }
        return KhBasisElement(state: s, factors: factors)
    }
 */
    
    public static func ==(b1: KhBasisElement, b2: KhBasisElement) -> Bool {
        return b1.state == b2.state && b1.factors == b2.factors
    }
    
    public static func <(b1: KhBasisElement, b2: KhBasisElement) -> Bool {
        return (b1.state < b2.state)
            || (b1.state == b2.state && b1.factors.lexicographicallyPrecedes(b2.factors) )
    }
    
    public var hashValue: Int {
        let s = state.components.reduce(0) { (res, b) in res &<< 1 | b }
        let f = factors.reduce(0) { (res, b) in res &<< 1 | b.rawValue }
        return s &<< 32 | f
    }
    
    public var description: String {
        return factors.map{ "\($0)" }.joined(separator: "⊗") + Format.sub(state.description.replacingOccurrences(of: ", ", with: ""))
    }
    
    public static func generateBasis(state: IntList, power n: Int) -> [KhBasisElement] {
        return IntList.binaryCombinations(length: n).map { I in
            let factors: [E] = I.components.map{ $0 == 0 ? .X : .I  }
            return KhBasisElement.init(state: state, factors: factors)
        }.sorted()
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
    
    public func applied<R: Ring>(_ μ: Product<R>, at: (Int, Int), to j: Int, state: IntList) -> FreeModule<KhBasisElement, R> {
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
    
    public func applied<R: Ring>(_ Δ: Coproduct<R>, at i: Int, to: (Int, Int), state: IntList) -> FreeModule<KhBasisElement, R> {
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

public func +<R: Ring>(m1: @escaping KhBasisElement.Product<R>, m2: @escaping KhBasisElement.Product<R>) -> KhBasisElement.Product<R> {
    return { (e1, e2) in m1(e1, e2) + m2(e1, e2) }
}

public func *<R: Ring>(r: R, m: @escaping KhBasisElement.Product<R>) -> KhBasisElement.Product<R> {
    return { (e1, e2) in m(e1, e2).map{ (x, a) in (x, r * a) } }
}

public func +<R: Ring>(c1: @escaping KhBasisElement.Coproduct<R>, c2: @escaping KhBasisElement.Coproduct<R>) -> KhBasisElement.Coproduct<R> {
    return { e in c1(e) + c2(e) }
}

public func *<R: Ring>(r: R, c: @escaping KhBasisElement.Coproduct<R>) -> KhBasisElement.Coproduct<R> {
    return { e in c(e).map{ (x, y, a) in (x, y, r * a) } }
}

