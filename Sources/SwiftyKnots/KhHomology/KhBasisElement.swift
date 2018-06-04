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
