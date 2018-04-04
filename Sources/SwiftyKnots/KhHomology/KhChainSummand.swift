//
//  KHBasis.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KhChainSummand: Equatable, CustomStringConvertible {
    public let link: Link
    public let state: LinkSpliceState
    public let components: [Link.Component]
    public let basis: [KhTensorElement]
    public let shift: Int
    
    public init(link L: Link, state: LinkSpliceState, shift: Int = 0) {
        let spliced = L.spliced(by: state)
        let comps = spliced.components
        let basis = KhChainSummand.generateBasis(state, comps.count, shift)
        
        self.link = spliced
        self.state = state
        self.components = comps
        self.basis = basis
        self.shift = shift
    }
    
    internal static func generateBasis(_ state: LinkSpliceState, _ power: Int, _ shift: Int) -> [KhTensorElement] {
        typealias E = KhTensorElement.E
        return (0 ..< power).reduce([[]]) { (res, _) -> [[E]] in
            res.flatMap{ factors -> [[E]] in
                [factors + [.I], factors + [.X]]
            }
        }.map{ KhTensorElement.init($0, state, shift) }
        .sorted()
    }

    public static func ==(B1: KhChainSummand, B2: KhChainSummand) -> Bool {
        return B1.basis == B2.basis && B1.shift == B2.shift
    }
    
    public var description: String {
        let n = Int( log2( Double(basis.count) ) )
        return Format.term(1, "V", n) + (shift != 0 ? "{\(shift)}" : "") + Format.sub(state.description)
    }
}

public struct KhTensorElement: FreeModuleBase, Comparable {
    internal let factors: [E]
    internal let state: LinkSpliceState
    internal let shift: Int
    
    internal init(_ factors: [E], _ state: LinkSpliceState, _ shift: Int) {
        self.factors = factors
        self.state = state
        self.shift = shift
    }
    
    public var degree: Int {
        return factors.sum{ e in e.degree } + shift
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
        
        static func μ(_ e1: E, _ e2: E) -> E? {
            switch (e1, e2) {
            case (.I, .I): return .I
            case (.I, .X), (.X, .I): return .X
            case (.X, .X): return nil
            }
        }
        
        static func Δ(_ e: E) -> [(E, E)] {
            switch e {
            case .I: return [(.I, .X), (.X, .I)]
            case .X: return [(.X, .X)]
            }
        }
    }
}
