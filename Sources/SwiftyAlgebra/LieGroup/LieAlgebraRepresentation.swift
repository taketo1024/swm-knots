//
//  Representation.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/23.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _LieAlgebraRepresentation: Representation, _LieAlgebraHom where Codomain == LinearEnd<BaseVectorSpace> { }

public struct LieAlgebraRepresentation<𝔤: LieAlgebra, V: VectorSpace>: _LieAlgebraRepresentation where 𝔤.CoeffRing == V.CoeffRing {
    public typealias CoeffRing = 𝔤.CoeffRing
    public typealias Domain   = 𝔤
    public typealias Codomain = LinearEnd<V>
    public typealias BaseVectorSpace = V

    private let f: (𝔤) -> LinearEnd<V>
    public init(_ f: @escaping (𝔤) -> LinearEnd<V>) {
        self.f = f
    }
    
    public subscript(X: 𝔤) -> LinearEnd<V> {
        return f(X)
    }
    
    public func applied(to X: 𝔤) -> LinearEnd<V> {
        return f(X)
    }
}
