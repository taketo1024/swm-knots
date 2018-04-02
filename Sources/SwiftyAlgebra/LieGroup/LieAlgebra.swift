//
//  LieAlgebra.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/23.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol LieAlgebra: VectorSpace {
    func bracket(_ Y: Self) -> Self
    static var adjointRepresentation: LieAlgebraRepresentation<Self, Self> { get }
}

public extension LieAlgebra {
    // MEMO ad[X] = [X, -]
    public static var adjointRepresentation: LieAlgebraRepresentation<Self, Self> {
        return LieAlgebraRepresentation { (X) -> LinearEnd<Self> in
            LinearEnd { Y in X.bracket(Y) }
        }
    }
}

public func bracket<𝔤: LieAlgebra>(_ X: 𝔤, _ Y: 𝔤) -> 𝔤 {
    return X.bracket(Y)
}

public protocol FiniteDimLieAlgebra: LieAlgebra, FiniteDimVectorSpace {
    static var killingForm: BilinearForm<Self> { get }
}

public extension FiniteDimLieAlgebra {
    // B(X, Y) = tr(ad(X) ∘ ad(Y))
    public static var killingForm: BilinearForm<Self> {
        let ad = adjointRepresentation
        return BilinearForm { (X: Self, Y: Self) -> CoeffRing in
            (ad[X] * ad[Y]).trace
        }
    }
}

// commutes with bracket: f[X, Y] = [f(X), f(Y)]
public protocol _LieAlgebraHom: _LinearMap where Domain: LieAlgebra, Codomain: LieAlgebra {}
