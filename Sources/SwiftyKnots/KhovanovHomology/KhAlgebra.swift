//
//  KhType.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2021/05/04.
//

import SwiftyMath

// The defining Frobenius algebra:
// A = R[X]/(X^2 - hX - t) = R[X]/(X - u)(X - v)

public enum KhovanovAlgebra<R: Ring> {
    case Khovanov, Lee, BarNatan
    case custom(h: R, t: R, u: R, v: R)
    
    var h: R {
        switch self {
        case .Khovanov:
            return .zero
        case .Lee:
            return .zero
        case .BarNatan:
            return .identity
        case let .custom(h: h, t: _, u: _, v: _):
            return h
        }
    }
    
    var t: R {
        switch self {
        case .Khovanov:
            return .zero
        case .Lee:
            return .identity
        case .BarNatan:
            return .zero
        case let .custom(h: _, t: t, u: _, v: _):
            return t
        }
    }
    
    var u: R {
        switch self {
        case .Khovanov:
            return .zero
        case .Lee:
            return -.identity
        case .BarNatan:
            return .zero
        case let .custom(h: _, t: _, u: u, v: _):
            return u
        }
    }
    
    var v: R {
        switch self {
        case .Khovanov:
            return .zero
        case .Lee:
            return .identity
        case .BarNatan:
            return .identity
        case let .custom(h: _, t: _, u: _, v: v):
            return v
        }
    }
    
    // A ⊗ A -> A
    public typealias Product = ModuleHom<
        LinearCombination<TensorGenerator<KhovanovAlgebraGenerator, KhovanovAlgebraGenerator>, R>,
        LinearCombination<KhovanovAlgebraGenerator, R>
    >
    public var product: Product {
        Product.linearlyExtend { e in
            switch e.factors {
            case (.X, .X):  // X^2 = hX + t1
                return .init(elements: [.X : h, .I : t])
                
            case (.I, .X),
                 (.X, .I):
                return .wrap(.X)
                
            case (.I, .I):
                return .wrap(.I)
            }
        }
    }
    
    // A -> A ⊗ A
    public typealias Coproduct = ModuleHom<
        LinearCombination<KhovanovAlgebraGenerator, R>,
        LinearCombination<TensorGenerator<KhovanovAlgebraGenerator, KhovanovAlgebraGenerator>, R>
    >
    public var coproduct: Coproduct {
        Coproduct.linearlyExtend { e in
            switch e {
            case .X: // ΔX = X⊗X + t1⊗1
                return .init(elements: [
                    (.X ⊗ .X) : .identity,
                    (.I ⊗ .I) : t
                ])
            case .I: // Δ1 = 1⊗X + X⊗1 - h1⊗1
                return .init(elements: [
                    (.I ⊗ .X) : .identity,
                    (.X ⊗ .I) : .identity,
                    (.I ⊗ .I) : -h
                ])
            }
        }
    }
}
