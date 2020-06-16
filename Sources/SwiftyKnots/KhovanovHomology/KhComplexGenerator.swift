//
//  KhBasisElement.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import SwiftyMath

public struct KhComplexGenerator: FreeModuleGenerator, TensorMonoid, Comparable, Codable {
    public let tensor: MultiTensorGenerator<KhAlgebraGenerator>
    public let state: Link.State

    public init(tensor: MultiTensorGenerator<KhAlgebraGenerator>, state: Link.State) {
        self.tensor = tensor
        self.state = state
    }

    public static func generateBasis(state: Link.State, power n: Int) -> [Self] {
        typealias A = KhAlgebraGenerator
        return generateBinarySequences(with: (A.I, A.X), length: n).map { factors in
            .init(tensor: MultiTensorGenerator(factors), state: state)
        }
    }

    public var degree: Int {
        state.weight
    }
    
    public var quantumDegree: Int {
        degree + tensor.degree + tensor.factors.count
    }
    
    public static func ⊗(x1: Self, x2: Self) -> Self {
        .init(tensor: x1.tensor ⊗ x2.tensor, state: x1.state + x2.state)
    }
    
    public static func <(b1: Self, b2: Self) -> Bool {
        (b1.state < b2.state)
            || (b1.state == b2.state && b1.tensor < b2.tensor)
    }

    public var description: String {
        tensor.description + Format.sub("(" + state.map{ $0.description }.joined() + ")")
    }
}

internal extension ModuleHom where Domain: FreeModule, Domain.Generator == MultiTensorGenerator<KhAlgebraGenerator>, Codomain == Domain {
    func callAsFunction(_ x: KhComplexGenerator, nextState: Link.State) -> LinearCombination<KhComplexGenerator, BaseRing> {
        self(x.tensor).mapGenerators { tensor in
            KhComplexGenerator(tensor: tensor, state: nextState)
        }
    }
}
