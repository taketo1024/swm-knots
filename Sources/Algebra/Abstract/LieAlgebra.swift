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
    var adjointRepresentation: LieAlgebraRepresentation<Self, Self> { get }
}

public extension LieAlgebra {
    // MEMO ad[X] = [X, -]
    public var adjointRepresentation: LieAlgebraRepresentation<Self, Self> {
        return LieAlgebraRepresentation { (X) -> LinearEnd<Self> in
            LinearEnd { Y in X.bracket(Y) }
        }
    }
}

public func bracket<𝔤: LieAlgebra>(_ X: 𝔤, _ Y: 𝔤) -> 𝔤 {
    return X.bracket(Y)
}

// commutes with bracket: f[X, Y] = [f(X), f(Y)]
public protocol _LieAlgebraHom: _LinearMap where Domain: LieAlgebra, Codomain: LieAlgebra {}
