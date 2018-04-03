//
//  LinearMap.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _LinearMap: ModuleHomType, VectorSpace where Domain: VectorSpace, Codomain: VectorSpace { }

public extension _LinearMap where Domain: FiniteDimVectorSpace, Codomain: FiniteDimVectorSpace {
    public init(matrix: DynamicMatrix<CoeffRing>) {
        self.init{ v in
            let x = DynamicVector(dim: Domain.dim, grid: v.standardCoordinates)
            let y = matrix * x
            return zip(y.grid, Codomain.standardBasis).sum { (a, w) in a * w }
        }
    }
    
    public var asMatrix: DynamicMatrix<CoeffRing> {
        let comps = Domain.standardBasis.enumerated().flatMap { (j, v) -> [MatrixComponent<CoeffRing>] in
            let w = self.applied(to: v)
            return w.standardCoordinates.enumerated().map { (i, a) in (i, j, a) }
        }
        return DynamicMatrix(rows: Codomain.dim, cols: Domain.dim, components: comps)
    }
    
    public var trace: CoeffRing {
        return asMatrix.trace
    }
    
    public var determinant: CoeffRing {
        return asMatrix.determinant
    }
}

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

public protocol _LinearEnd: _LinearMap, EndType, LieAlgebra {}

public extension _LinearEnd {
    public func bracket(_ g: Self) -> Self {
        let f = self
        return f ∘ g - g ∘ f
    }
}

public typealias LinearEnd<V: VectorSpace> = LinearMap<V, V>
extension LinearEnd: _LinearEnd where V == W {}

public protocol _LinearAut: AutType where Domain: VectorSpace {}

public struct LinearAut<V: VectorSpace>: _LinearAut {
    public func composed(with f: LinearAut<V>) -> LinearAut<V> {
        fatalError()
    }
    
    public static func ∘ (g: LinearAut<V>, f: LinearAut<V>) -> LinearAut<V> {
        fatalError()
    }
    
    public init(_ g: LinearMap<V, V>) {
        fatalError()
    }
    
    public var asSuper: LinearMap<V, V> {
        fatalError()
    }
    
    public static func contains(_ g: LinearMap<V, V>) -> Bool {
        fatalError()
    }
    
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
