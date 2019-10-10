//
//  KhAlgebraGenerator.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/10.
//

import SwiftyMath

public enum KhAlgebraGenerator: String, FreeModuleGenerator, Codable {
    case I, X // A = R[X]/(X^2 + hX + t) = R<1, X>

    public var degree: Int {
        (self == .I) ? 0 : -2
    }
    
    public static func <(e1: Self, e2: Self) -> Bool {
        e1.degree < e2.degree
    }

    public var description: String {
        (self == .I) ? "1" : "X"
    }
    
    public typealias Product<R: Ring> = ModuleHom<FreeModule<TensorGenerator<Self, Self>, R>, FreeModule<Self, R>>
    public typealias Coproduct<R: Ring> = ModuleHom<FreeModule<Self, R>, FreeModule<TensorGenerator<Self, Self>, R>>
    
    public static func product<R: Ring>(h: R = .zero, t: R = .zero) -> Product<R> {
        Product<R>.linearlyExtend { e in
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

    public static func coproduct<R: Ring>(h: R = .zero, t: R = .zero) -> Coproduct<R> {
        Coproduct<R>.linearlyExtend { e in
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

