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

public struct LinearMap<X: VectorSpace, Y: VectorSpace>: _LinearMap where X.CoeffRing == Y.CoeffRing {
    public typealias CoeffRing = X.CoeffRing
    public typealias Domain = X
    public typealias Codomain = Y
    
    private let f: (X) -> Y
    public init(_ f: @escaping (X) -> Y) {
        self.f = f
    }
    
    public func applied(to x: X) -> Y {
        return f(x)
    }
    
    public func composed<W>(with f: LinearMap<W, X>) -> LinearMap<W, Y> {
        return LinearMap<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<Z>(g: LinearMap<Y, Z>, f: LinearMap<X, Y>) -> LinearMap<X, Z> {
        return g.composed(with: f)
    }
}

public extension LinearMap where X: FiniteDimVectorSpace, Y: FiniteDimVectorSpace {
    public var asMatrix: Matrix<Dynamic, Dynamic, CoeffRing> {
        fatalError()
    }
}

public typealias LinearEnd<X: VectorSpace> = LinearMap<X, X>

// TODO conform to Endomorphism, LieAlgebra
public extension LinearEnd where X == Y {
    public func bracket(_ g: LinearEnd<X>) -> LinearEnd<X> {
        let f = self
        return f ∘ g - g ∘ f
    }
}

public extension LinearEnd where X: FiniteDimVectorSpace {
    public var asMatrix: Matrix<_1, _1, CoeffRing> {
        fatalError("TODO")
    }
}

public struct LinearAut<X: VectorSpace>: Aut {
    public typealias Domain = X
    public typealias Codomain = X

    fileprivate let f: (X) -> X
    public init(_ f: @escaping (X) -> X) {
        self.f = f
    }
    
    public func applied(to x: X) -> X {
        return f(x)
    }
    
    public var inverse: LinearAut<X> {
        fatalError("Cannot find inverse for general linear aut.")
    }
}

public extension LinearAut where X: FiniteDimVectorSpace {
    public var inverse: LinearAut<X> {
        fatalError("TODO")
    }
}
