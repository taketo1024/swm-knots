//
//  KHBasis.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KHBasis: Equatable, CustomStringConvertible {
    public let state: LinkSpliceState
    public let elements: [KHBasisElement]
    public let shifted: Int
    
    internal init(_ state: LinkSpliceState, _ elements: [KHBasisElement], shifted: Int = 0) {
        self.state = state
        self.elements = elements
        self.shifted = shifted
    }
    
    public static func from(state: LinkSpliceState, components n: Int) -> KHBasis {
        let V = KHBasis(state, [KHBasisElement(state, .I), KHBasisElement(state, .X)])
        return V.tensorPow(n)
    }
    
    public func shift(_ n: Int) -> KHBasis {
        return KHBasis(state, elements, shifted: shifted + n)
    }
    
    public static func ⊗(B1: KHBasis, B2: KHBasis) -> KHBasis {
        assert(B1.state == B2.state)
        let elements = B1.elements.allCombinations(with: B2.elements).map { (e1, e2) in
            e1 ⊗ e2
            }.sorted()
        return KHBasis(B1.state, elements)
    }
    
    public func tensorPow(_ n: Int) -> KHBasis {
        assert(n >= 1)
        if n == 1 {
            return self
        } else {
            return self ⊗ self.tensorPow(n - 1)
        }
    }
    
    
    
    public static func ==(B1: KHBasis, B2: KHBasis) -> Bool {
        return B1.elements == B2.elements && B1.shifted == B2.shifted
    }
    
    public var description: String {
        let n = Int( log2( Double(elements.count) ) )
        return Format.term(1, "A", n) + (shifted != 0 ? "{\(shifted)}" : "")
    }
}

public struct KHBasisElement: FreeModuleBase, Comparable {
    internal let state: LinkSpliceState
    internal let elements: [E]
    
    internal init(_ state: LinkSpliceState, _ elements: [E]) {
        self.state = state
        self.elements = elements
    }
    
    internal init(_ state: LinkSpliceState, _ e: E) {
        self.init(state, [e])
    }
    
    public var degree: Int {
        return elements.sum{ e in e.degree }
    }
    
    internal func applyμ(at i: Int, _ newState: LinkSpliceState) -> KHBasisElement {
        let (e1, e2) = (elements[i], elements[i + 1])
        let a1 = elements[0 ..< i]
        let a2 = elements[i + 2 ..< elements.count]
        
        //        switch (e1, e2) {
        //        case (.I, .I):
        //        }
        fatalError()
    }
    
    internal func applyΔ(at i: Int, _ newState: LinkSpliceState) -> [KHBasisElement] {
        //        let (e1, e2) =
        fatalError()
    }
    
    public static func ⊗(b1: KHBasisElement, b2: KHBasisElement) -> KHBasisElement {
        assert(b1.state == b2.state)
        return KHBasisElement(b1.state, b1.elements + b2.elements)
    }
    
    public static func ==(b1: KHBasisElement, b2: KHBasisElement) -> Bool {
        return b1.state == b2.state && b1.elements == b2.elements
    }
    
    public static func <(b1: KHBasisElement, b2: KHBasisElement) -> Bool {
        return (b1.state < b2.state)
            || (b1.state == b2.state
                && (b1.degree < b2.degree
                    || (b1.degree == b2.degree
                        && b1.elements.lexicographicallyPrecedes(b2.elements)
                    )
                )
        )
    }
    
    public var hashValue: Int {
        return elements.reduce(0) { (res, e) in
            res &<< 2 | (e == .I ? 2 : 1)
        }
    }
    
    public var description: String {
        return elements.map{ "\($0)" }.joined(separator: "⊗") + Format.sub(state.description)
    }
    
    enum E: Equatable, Comparable {
        case I
        case X
        
        var degree: Int {
            switch self {
            case .I: return +1
            case .X: return -1
            }
        }
        
        static func <(e1: E, e2: E) -> Bool {
            return e1.degree < e2.degree
        }
        
    }
}
