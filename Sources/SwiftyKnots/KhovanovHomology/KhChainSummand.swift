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
    public let basis: [KhTensorElement]
    public let shifted: Int
    
    public init(link L: Link, state: LinkSpliceState, shifted: Int = 0) {
        let spliced = L.spliced(by: state)
        let basis = KhChainSummand.generate(state: state, power: spliced.components)
        self.init(link: spliced, state: state, basis: basis, shifted: shifted)
    }
    
    internal init(link: Link, state: LinkSpliceState, basis: [KhTensorElement], shifted: Int) {
        self.link = link
        self.state = state
        self.basis = basis
        self.shifted = shifted
    }
    
    public func shift(_ n: Int) -> KhChainSummand {
        return KhChainSummand(link: link, state: state, basis: basis, shifted: shifted + n)
    }
    
    internal static func generate(state: LinkSpliceState, power n: Int) -> [KhTensorElement] {
        typealias E = KhTensorElement.E
        return (0 ..< n).reduce([[]]) { (res, _) -> [[E]] in
            res.flatMap{ factors -> [[E]] in
                [factors + [.I], factors + [.X]]
            }
        }.map{ KhTensorElement.init($0, state) }
        .sorted()
    }

    public static func ==(B1: KhChainSummand, B2: KhChainSummand) -> Bool {
        return B1.basis == B2.basis && B1.shifted == B2.shifted
    }
    
    public var description: String {
        let n = Int( log2( Double(basis.count) ) )
        return Format.term(1, "A", n) + (shifted != 0 ? "{\(shifted)}" : "")
    }
}

public struct KhTensorElement: FreeModuleBase, Comparable {
    internal let factors: [E]
    internal let state: LinkSpliceState
    
    internal init(_ factors: [E], _ state: LinkSpliceState) {
        self.factors = factors
        self.state = state
    }
    
    public var degree: Int {
        return factors.sum{ e in e.degree }
    }
    
    internal func μ(at: (Int, Int), to: Int) -> KhTensorElement {
//        let (i, j) = at
//        let (e1, e2) = (factors[i], factors[j])
        //        switch (e1, e2) {
        //        case (.I, .I):
        //        }
        fatalError()
    }
    
    internal func Δ(at i: Int, _ newState: LinkSpliceState) -> [KhTensorElement] {
        //        let (e1, e2) =
        fatalError()
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
        return "(\(factors.map{ "\($0)" }.joined(separator: "⊗")))\(Format.sub(state.description))"
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
