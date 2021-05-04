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
    
    public func modified(state: Link.State? = nil, modifier: (inout [KhAlgebraGenerator]) -> Void) -> Self {
        var factors = tensor.factors
        modifier(&factors)
        return KhComplexGenerator(tensor: MultiTensorGenerator(factors), state: state ?? self.state)
    }
    
    public func applied<R: Ring>(_ m: KhAlgebraGenerator.Product<R>, inputIndices: (Int, Int), outputIndex: Int, nextState: Link.State) -> LinearCombination<KhComplexGenerator, R> {
        let factors = tensor.factors
        let (x1, x2) = (factors[inputIndices.0], factors[inputIndices.1])
        return m(x1 ⊗ x2).mapGenerators { y in
            self.modified(state: nextState) { (factors: inout [KhAlgebraGenerator]) in
                factors.remove(at: inputIndices.1)
                factors.remove(at: inputIndices.0)
                factors.insert(y, at: outputIndex)
            }
        }
    }

    public func applied<R: Ring>(_ Δ: KhAlgebraGenerator.Coproduct<R>, inputIndex: Int, outputIndices: (Int, Int), nextState: Link.State) -> LinearCombination<KhComplexGenerator, R> {
        let factors = tensor.factors
        let x = factors[inputIndex]
        return Δ(x).mapGenerators { y in
            self.modified(state: nextState) { (factors: inout [KhAlgebraGenerator]) in
                factors.remove(at: inputIndex)
                factors.insert(y.factors.0, at: outputIndices.0)
                factors.insert(y.factors.1, at: outputIndices.1)
            }
        }
    }

    public var description: String {
        tensor.description + Format.sub("(" + state.map{ $0.description }.joined() + ")")
    }
}
