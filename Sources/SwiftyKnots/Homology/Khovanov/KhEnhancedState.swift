//
//  KhBasisElement.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KhEnhancedState: FreeModuleBasis, Comparable, Codable {
    public let state: IntList
    internal let tensor: FreeTensor<E>
    
    internal init(_ state: IntList, _ tensor: FreeTensor<E>) {
        self.state = state
        self.tensor = tensor
    }
    
    public var degree: Int {
        return tensor.degree + state.components.count{ $0 == 1 }
    }
    
    public func qDegree(in L: Link) -> Int {
        let (n⁺, n⁻) = (L.crossingNumber⁺, L.crossingNumber⁻)
        return degree + n⁺ - 2 * n⁻
    }
    
    public typealias   Product<R: Ring> = FreeTensor<E>.Product<R>
    public typealias Coproduct<R: Ring> = FreeTensor<E>.Coproduct<R>
    
    public func applied<R: Ring>(_ μ: Product<R>, at: (Int, Int), to: Int, state: IntList) -> FreeModule<KhEnhancedState, R> {
        return tensor.applied(μ, at: at, to: to).mapBasis {
            KhEnhancedState(state, $0)
        }
    }
    
    public func applied<R: Ring>(_ Δ: Coproduct<R>, at: Int, to: (Int, Int), state: IntList) -> FreeModule<KhEnhancedState, R> {
        return tensor.applied(Δ, at: at, to: to).mapBasis {
            KhEnhancedState(state, $0)
        }
    }
    
    public func mapFactors<R: Ring>(_ f: (E) -> [(E, R)]) -> FreeModule<KhEnhancedState, R> {
        return tensor.mapFactors(f).mapBasis { KhEnhancedState(state, $0) }
    }
    
    public static func <(b1: KhEnhancedState, b2: KhEnhancedState) -> Bool {
        return (b1.state < b2.state)
            || (b1.state == b2.state && b1.tensor < b2.tensor)
    }
    
    public static func generateBasis(state: IntList, power n: Int) -> [KhEnhancedState] {
        return IntList.binaryCombinations(length: n).map { I in
            let factors: [E] = I.components.map{ $0 == 0 ? .X : .I  }
            return KhEnhancedState.init(state, FreeTensor(factors))
            }.sorted()
    }
    
    public var description: String {
        return tensor.description + Format.sub(state.description.replacingOccurrences(of: ", ", with: ""))
    }
    
    public enum E: Int, FreeModuleBasis, Codable {
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

extension KhEnhancedState {
    // Khovanov's map
    public static func product<R: Ring>(_ type: R.Type, h: R = .zero, t: R = .zero) -> Product<R> {
        return Product { (x: Tensor<E, E>) -> FreeModule<KhEnhancedState.E, R> in
            switch x.factors {
            case (.I, .I):
                return .wrap(.I)
            case (.I, .X), (.X, .I):
                return .wrap(.X)
            case (.X, .X):
                return h * .wrap(.X) + t * .wrap(.I)
            }
        }
    }
    
    public static func coproduct<R: Ring>(_ type: R.Type, h: R = .zero, t: R = .zero) -> Coproduct<R> {
        return Coproduct { (e: E) in
            switch e {
            case .I:
                return .wrap(Tensor(.I, .X)) + .wrap(Tensor(.X, .I)) - h * .wrap(Tensor(.I, .I))
            case .X:
                return .wrap(Tensor(.X, .X)) + t * .wrap(Tensor(.I, .I))
            }
        }
    }
}
