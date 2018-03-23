//
//  VectorSpace.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/18.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol VectorSpace: Module where CoeffRing: Field { }

public protocol FiniteDimVectorSpace: VectorSpace {
    static var dim: Int { get }
    static var standardBasis: [Self] { get }
    var standardCoordinates: [CoeffRing] { get }
}

public protocol _LinearMap: _ModuleHom, VectorSpace where Domain: VectorSpace, Codomain: VectorSpace { }

public struct LinearMap<V: VectorSpace, W: VectorSpace>: _LinearMap where V.CoeffRing == W.CoeffRing {
    public typealias CoeffRing = V.CoeffRing
    public typealias Domain = V
    public typealias Codomain = W
    
    private let f: (V) -> W
    public init(_ f: @escaping (V) -> W) {
        self.f = f
    }
    
    public func applied(to x: V) -> W {
        return f(x)
    }
    
    public func composed<U>(with f: LinearMap<U, V>) -> LinearMap<U, W> {
        return LinearMap<U, W> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<X>(g: LinearMap<W, X>, f: LinearMap<V, W>) -> LinearMap<V, X> {
        return g.composed(with: f)
    }
}

public extension LinearMap where V: FiniteDimVectorSpace, W: FiniteDimVectorSpace {
    public var asMatrix: Matrix<Dynamic, Dynamic, CoeffRing> {
        fatalError()
    }
}

public protocol _LinearEnd: _LinearMap, End, LieAlgebra {}

public extension _LinearEnd {
    public func bracket(_ g: Self) -> Self {
        let f = self
        return f ∘ g - g ∘ f
    }
}

public extension _LinearEnd where Domain: FiniteDimVectorSpace {
    public var asMatrix: Matrix<_1, _1, CoeffRing> {
        fatalError("TODO")
    }
}

// TODO use typealias + conditional conformance instead.
public struct LinearEnd<V: VectorSpace>: _LinearEnd {
    public typealias CoeffRing = V.CoeffRing
    public typealias Domain = V
    public typealias Codomain = V
    
    private let f: (V) -> V
    public init(_ f: @escaping (V) -> V) {
        self.f = f
    }
    
    public func applied(to x: V) -> V {
        return f(x)
    }
}

public protocol _LinearAut: Aut where Domain: VectorSpace {}

public struct LinearAut<V: VectorSpace>: _LinearAut {
    public typealias Domain = V
    public typealias Codomain = V
    public typealias Super = LinearEnd<V>

    fileprivate let f: (V) -> V
    public init(_ f: @escaping (V) -> V) {
        self.f = f
    }
    
    public func applied(to x: V) -> V {
        return f(x)
    }
    
    public var inverse: LinearAut<V> {
        fatalError("Cannot find inverse for general linear aut.")
    }
}

public extension LinearAut where V: FiniteDimVectorSpace {
    public var inverse: LinearAut<V> {
        fatalError("TODO")
    }
}
