//
//  File.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/04/11.
//

import Foundation

public typealias AbstractVector<K: Field> = FreeModule<AbstractBasisElement, K>

public extension AbstractVector where A == AbstractBasisElement, CoeffRing: Field {
    public init(_ components: [CoeffRing]) {
        self.init(basis: AbstractBasisElement.generateBasis(components.count), components: components)
    }
    
    public init(_ components: CoeffRing ...) {
        self.init(components)
    }
    
    public static func standardBasis(dim: Int) -> [AbstractVector<CoeffRing>] {
        let basis = AbstractBasisElement.generateBasis(dim)
        return basis.map { e in AbstractVector(e) }
    }
    
    public static func ⊗(v: AbstractVector<CoeffRing>, w: AbstractVector<CoeffRing>) -> AbstractTensor<CoeffRing> {
        return v.basis.allCombinations(with: w.basis).sum { (e1, e2) -> AbstractTensor<CoeffRing> in
            let t = Tensor(e1, e2)
            return AbstractTensor(t, v[e1] * w[e2])
        }
    }
}

public typealias AbstractTensor<K: Field> = FreeModule<Tensor<AbstractBasisElement>, K>

public extension AbstractTensor where A == Tensor<AbstractBasisElement>, CoeffRing: Field {
    public static func ⊗(v: AbstractTensor<CoeffRing>, w: AbstractTensor<CoeffRing>) -> AbstractTensor<CoeffRing> {
        return v.basis.allCombinations(with: w.basis).sum { (e1, e2) -> AbstractTensor<CoeffRing> in
            let t = e1 ⊗ e2
            return AbstractTensor(t, v[e1] * v[e2])
        }
    }
}
