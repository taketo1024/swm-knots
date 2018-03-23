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
}

public func bracket<𝔤: LieAlgebra>(_ X: 𝔤, _ Y: 𝔤) -> 𝔤 {
    return X.bracket(Y)
}

// commutes with bracket
public protocol _LieAlgebraHom: _LinearMap where Domain: LieAlgebra, Codomain: LieAlgebra {}
