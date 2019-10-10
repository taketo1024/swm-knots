//
//  KhBasisElement.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import SwiftyMath

public struct KhEnhancedState: FreeModuleGenerator, Comparable, Codable {
    public let state: Link.State
    internal let tensorFactors: [E]

    internal init(_ state: Link.State, _ tensorFactors: [E]) {
        self.state = state
        self.tensorFactors = tensorFactors
    }

    public var degree: Int {
        tensorFactors.sum { $0.degree } + state.count{ $0 == 1 } + tensorFactors.count
    }

    public static func <(b1: KhEnhancedState, b2: KhEnhancedState) -> Bool {
        (b1.state < b2.state)
            || (b1.state == b2.state && b1.tensorFactors < b2.tensorFactors)
    }

    public static func generateBasis(state: Link.State, power n: Int) -> [KhEnhancedState] {
        [Int].binaryCombinations(length: n).map { I in
            KhEnhancedState.init(state, I.map{ $0 == 0 ? .X : .I  })
        }.sorted()
    }

    public var description: String {
        tensorFactors.map{ $0.description }.joined(separator: "⊗")
            + Format.sub("(" + state.map{ $0.description }.joined() + ")")
    }

    public enum E: Int, FreeModuleGenerator, Codable {
        case I =  0
        case X = -2

        public var degree: Int {
            rawValue
        }

        public static func <(e1: E, e2: E) -> Bool {
            e1.degree < e2.degree
        }

        public var description: String {
            (self == .I) ? "1" : "X"
        }
    }
    
    struct Product<R: Ring> {
        let h, t: R
        init(_ h: R, _ t: R) {
            (self.h, self.t) = (h, t)
        }
        
        private func applied(to: (E, E)) -> [(E, R)] {
            switch to {
            case (.I, .I):
                return [(.I, .identity)]
            case (.I, .X), (.X, .I):
                return [(.X, .identity)]
            case (.X, .X):
                return [(.X, h), (.I, t)]
            }
        }
        
        func applied(to x: KhEnhancedState, at: (Int, Int), to j: Int, state: Link.State) -> FreeModule<KhEnhancedState, R> {
            let (i1, i2) = at
            let (e1, e2) = (x.tensorFactors[i1], x.tensorFactors[i2])
            let values = applied(to: (e1, e2)).map { (e, r) -> (KhEnhancedState, R) in
                var factors = x.tensorFactors
                factors.remove(at: i2)
                factors.remove(at: i1)
                factors.insert(e, at: j)
                return (KhEnhancedState(state, factors), r)
            }
            return FreeModule(elements: values)
        }
    }
    
    struct Coproduct<R: Ring> {
        let h, t: R
        init(_ h: R, _ t: R) {
            (self.h, self.t) = (h, t)
        }

        private func applied(to: E) -> [(E, E, R)] {
            switch to {
            case .I:
                return [(.I, .X, .identity), (.X, .I, .identity), (.I, .I, -h)]
            case .X:
                return [(.X, .X, .identity), (.I, .I, t)]
            }
        }
        
        
        func applied(to x: KhEnhancedState, at i: Int, to: (Int, Int), state: Link.State) -> FreeModule<KhEnhancedState, R> {
            let (j1, j2) = to
            let e = x.tensorFactors[i]
            let values = applied(to: e).map { (e1, e2, r) -> (KhEnhancedState, R) in
                var factors = x.tensorFactors
                factors.remove(at: i)
                factors.insert(e1, at: j1)
                factors.insert(e2, at: j2)
                return (KhEnhancedState(state, factors), r)
            }
            return FreeModule(elements: values)
        }
    }
}
