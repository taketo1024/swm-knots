//
//  KhBasisElement.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KhEnhancedState: FreeModuleGenerator, Comparable, Codable {
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
    
    public typealias   Product<R: Ring> = ModuleHom<FreeModule<Tensor<E, E>, R>, FreeModule<E, R>>
    public typealias Coproduct<R: Ring> = ModuleHom<FreeModule<E, R>, FreeModule<Tensor<E, E>, R>>
    
    public func applied<R: Ring>(_ m: Product<R>, at: (Int, Int), to j: Int, state: IntList) -> FreeModule<KhEnhancedState, R> {
        let (i1, i2) = at
        let (e1, e2) = (tensor[i1], tensor[i2])
        return m.applied(to: .wrap(Tensor(e1, e2))).convertGenerators { e -> KhEnhancedState in
            var factors = tensor.factors
            factors.remove(at: i2)
            factors.remove(at: i1)
            factors.insert(e, at: j)
            return KhEnhancedState(state, FreeTensor(factors))
        }
    }
    
    public func applied<R: Ring>(_ Δ: Coproduct<R>, at i: Int, to: (Int, Int), state: IntList) -> FreeModule<KhEnhancedState, R> {
        let (j1, j2) = to
        let e = tensor[i]
        return Δ.applied(to: .wrap(e)).convertGenerators { t in
            let (e1, e2) = t.factors
            var factors = tensor.factors
            factors.remove(at: i)
            factors.insert(e1, at: j1)
            factors.insert(e2, at: j2)
            return KhEnhancedState(state, FreeTensor(factors))
        }
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
    
    public enum E: Int, FreeModuleGenerator, Codable {
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
        return Product.linearlyExtend { x in
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
        return Coproduct.linearlyExtend { e in
            switch e {
            case .I:
                return .wrap(Tensor(.I, .X)) + .wrap(Tensor(.X, .I)) - h * .wrap(Tensor(.I, .I))
            case .X:
                return .wrap(Tensor(.X, .X)) + t * .wrap(Tensor(.I, .I))
            }
        }
    }
}
