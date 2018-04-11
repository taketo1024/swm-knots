//
//  File.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/04/11.
//

import Foundation

public typealias AbstractVector<K: Field> = FreeModule<AbstractBasisElement, K>

extension AbstractVector where A == AbstractBasisElement, CoeffRing: Field {
    public init(_ components: [CoeffRing]) {
        self.init(basis: AbstractBasisElement.generateBasis(components.count), components: components)
    }
    
    public init(_ components: CoeffRing ...) {
        self.init(components)
    }
    
    public var asTensor: AbstractTensor<CoeffRing> {
        return AbstractTensor( self.map{ (e, a) in (Tensor(e), a) } )
    }
    
    public static func standardBasis(dim: Int) -> [AbstractVector<CoeffRing>] {
        let basis = AbstractBasisElement.generateBasis(dim)
        return basis.map { e in AbstractVector(e) }
    }
    
    public static func ⊗(v: AbstractVector<CoeffRing>, w: AbstractVector<CoeffRing>) -> AbstractTensor<CoeffRing> {
        return v.asTensor ⊗ w.asTensor
    }
}

public typealias AbstractTensor<K: Field> = FreeModule<Tensor<AbstractBasisElement>, K>

public extension AbstractTensor where A == Tensor<AbstractBasisElement>, CoeffRing: Field {
    public static func ⊗(v: AbstractTensor<CoeffRing>, w: AbstractTensor<CoeffRing>) -> AbstractTensor<CoeffRing> {
        return v.basis.allCombinations(with: w.basis).sum { (e1, e2) -> AbstractTensor<CoeffRing> in
            let t = e1 ⊗ e2
            return AbstractTensor(t, v[e1] * w[e2])
        }
    }
}

public typealias AbstractLinearMap<K: Field> = FreeModuleHom<AbstractBasisElement, AbstractBasisElement, K>

public extension AbstractLinearMap where A == AbstractBasisElement, A == B, R: Field {
    public init<n, m>(matrix: Matrix<n, m, R>) {
        self.init { (e: AbstractBasisElement) -> AbstractVector<R> in
            AbstractVector(matrix.colVector(e.index).grid)
        }
    }
    
    public var asTensorMap: AbstractTensorMap<R> {
        return AbstractTensorMap { (e: Tensor<AbstractBasisElement>) -> AbstractTensor<R> in
            (e.factors.count == 1) ? self.applied(to: e.factors[0]).asTensor : .zero
        }
    }
    
    public static func ⊗(f: AbstractLinearMap<CoeffRing>, g: AbstractLinearMap<CoeffRing>) -> AbstractTensorMap<CoeffRing> {
        return f.asTensorMap ⊗ g.asTensorMap
    }
}

public typealias AbstractTensorMap<K: Field> = FreeModuleHom<Tensor<AbstractBasisElement>, Tensor<AbstractBasisElement>, K>

public extension AbstractTensorMap where A == Tensor<AbstractBasisElement>, A == B, R: Field {
    public static func ⊗(f: AbstractTensorMap<CoeffRing>, g: AbstractTensorMap<CoeffRing>) -> AbstractTensorMap<CoeffRing> {
        return AbstractTensorMap { (e: Tensor<AbstractBasisElement>) -> AbstractTensor<CoeffRing> in
            let n = e.factors.count
            return (0 ..< n).sum { i in
                let e1 = Tensor(e.factors.prefix(i).toArray())
                let e2 = Tensor(e.factors.suffix(n - i).toArray())
                return f.applied(to: e1) ⊗ g.applied(to: e2)
            }
        }
    }
}
