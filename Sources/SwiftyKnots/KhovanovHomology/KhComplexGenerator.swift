//
//  KhBasisElement.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import SwiftyMath

public struct KhComplexGenerator: FreeModuleGenerator, Comparable, Codable {
    public let state: Link.State
    internal let tensorFactors: [KhAlgebraGenerator]

    internal init(_ state: Link.State, _ tensorFactors: [KhAlgebraGenerator]) {
        self.state = state
        self.tensorFactors = tensorFactors
    }

    public static func generateBasis(state: Link.State, power n: Int) -> [Self] {
        [Int].binaryCombinations(length: n).map { I in
            .init(state, I.map{ $0 == 0 ? .X : .I  })
        }.sorted()
    }

    public var degree: Int {
        tensorFactors.sum { $0.degree } + state.count{ $0 == 1 } + tensorFactors.count
    }
    
    public func applied<R: Ring>(product: KhAlgebraGenerator.Product<R>, at: (Int, Int), to j: Int, state: Link.State) -> FreeModule<KhComplexGenerator, R> {
        let (i1, i2) = at
        let (e1, e2) = (tensorFactors[i1], tensorFactors[i2])
        
        return product.applied(to: e1 ⊗ e2).mapGenerators{ e -> Self in
            let factors = self.tensorFactors.with { factors in
                factors.remove(at: i2)
                factors.remove(at: i1)
                factors.insert(e, at: j)
            }
            return KhComplexGenerator(state, factors)
        }
    }

    func applied<R: Ring>(coproduct: KhAlgebraGenerator.Coproduct<R>, at i: Int, to: (Int, Int), state: Link.State) -> FreeModule<KhComplexGenerator, R> {
        let (j1, j2) = to
        let e = tensorFactors[i]
        
        return coproduct.applied(to: e).mapGenerators { t -> Self in
            let (e1, e2) = t.factors
            let factors = self.tensorFactors.with { factors in
                factors.remove(at: i)
                factors.insert(e1, at: j1)
                factors.insert(e2, at: j2)
            }
            return KhComplexGenerator(state, factors)
        }
    }

    public static func <(b1: Self, b2: Self) -> Bool {
        (b1.state < b2.state)
            || (b1.state == b2.state && b1.tensorFactors < b2.tensorFactors)
    }

    public var description: String {
        tensorFactors.map{ $0.description }.joined(separator: "⊗")
            + Format.sub("(" + state.map{ $0.description }.joined() + ")")
    }
}
