//
//  KhBasisElement.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import SwiftyMath

public struct KhovanovGenerator: FreeModuleGenerator, TensorMonoid, Comparable, Codable {
    public let tensor: MultiTensorGenerator<A>
    public let state: Link.State

    public init(tensor: MultiTensorGenerator<A>, state: Link.State) {
        self.tensor = tensor
        self.state = state
    }

    public static func generateBasis(state: Link.State, power n: Int) -> [Self] {
        let (I, X) = (A.I, A.X)
        return generateBinarySequences(with: (I, X), length: n).map { factors in
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
    
    private func modified(state: Link.State? = nil, modifier: (inout [A]) -> Void) -> Self {
        var factors = tensor.factors
        modifier(&factors)
        return KhovanovGenerator(tensor: MultiTensorGenerator(factors), state: state ?? self.state)
    }
    
    public func merge<R: Ring>(type: KhovanovType<R>, inputIndices: (Int, Int), outputIndex: Int, nextState: Link.State) -> LinearCombination<KhovanovGenerator, R> {
        let m = type.product
        let factors = tensor.factors
        let (x1, x2) = (factors[inputIndices.0], factors[inputIndices.1])
        return m(x1 ⊗ x2).mapGenerators { y in
            self.modified(state: nextState) { (factors: inout [A]) in
                factors.remove(at: inputIndices.1)
                factors.remove(at: inputIndices.0)
                factors.insert(y, at: outputIndex)
            }
        }
    }

    public func split<R: Ring>(type: KhovanovType<R>, inputIndex: Int, outputIndices: (Int, Int), nextState: Link.State) -> LinearCombination<KhovanovGenerator, R> {
        let Δ = type.coproduct
        let factors = tensor.factors
        let x = factors[inputIndex]
        return Δ(x).mapGenerators { y in
            self.modified(state: nextState) { (factors: inout [A]) in
                factors.remove(at: inputIndex)
                factors.insert(y.factors.0, at: outputIndices.0)
                factors.insert(y.factors.1, at: outputIndices.1)
            }
        }
    }

    public var description: String {
        tensor.description + Format.sub("(" + state.map{ $0.description }.joined() + ")")
    }
    
    public enum A: Int8, FreeModuleGenerator, Codable {
        case I = 0
        case X = 1

        public var degree: Int {
            (self == .I) ? 0 : -2
        }
        
        public static func <(e1: Self, e2: Self) -> Bool {
            e1.degree < e2.degree
        }

        public var description: String {
            (self == .I) ? "1" : "X"
        }
    }
}
