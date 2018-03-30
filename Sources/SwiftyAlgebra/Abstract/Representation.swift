//
//  Representation.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/23.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol Representation: Map {
    associatedtype VectorSpace
}

public protocol _GroupRepresentation: Representation, _GroupHom where Codomain == LinearAut<VectorSpace> { }

public struct GroupRepresentation<G: Group, V: VectorSpace>: _GroupRepresentation {
    public typealias Domain   = G
    public typealias Codomain = LinearAut<V>
    public typealias VectorSpace = V
    
    private let f: (G) -> LinearAut<V>
    public init(_ f: @escaping (G) -> LinearAut<V>) {
        self.f = f
    }
    
    public subscript(g: G) -> LinearAut<V> {
        return f(g)
    }
    
    public func applied(to g: G) -> LinearAut<V> {
        return f(g)
    }
}

public protocol _LieAlgebraRepresentation: Representation, _LieAlgebraHom where Codomain == LinearEnd<VectorSpace> { }

public struct LieAlgebraRepresentation<𝔤: LieAlgebra, V: VectorSpace>: _LieAlgebraRepresentation where 𝔤.CoeffRing == V.CoeffRing {
    public typealias CoeffRing = 𝔤.CoeffRing
    public typealias Domain   = 𝔤
    public typealias Codomain = LinearEnd<V>
    public typealias VectorSpace = V

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
