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

public protocol _ProductVectorSpace: VectorSpace, _ProductModule {}

public struct ProductVectorSpace<V1: VectorSpace, V2: VectorSpace>: _ProductVectorSpace where V1.CoeffRing == V2.CoeffRing {
    public typealias Left = V1
    public typealias Right = V2
    public typealias CoeffRing = V1.CoeffRing
    
    public let _1: V1
    public let _2: V2
    
    public init(_ v1: V1, _ v2: V2) {
        self._1 = v1
        self._2 = v2
    }
}

// a Field considered as a 1-dim VectorSpace over itself.
public struct AsVectorSpace<X: Field>: FiniteDimVectorSpace {
    public typealias CoeffRing = X
    
    public let value: X
    public init(_ x: X) {
        self.value = x
    }
    
    public static var dim: Int {
        return 1
    }
    
    public static var standardBasis: [AsVectorSpace<X>] {
        return [AsVectorSpace(.identity)]
    }
    
    public var standardCoordinates: [X] {
        return [value]
    }
    
    public static var zero: AsVectorSpace<X> {
        return AsVectorSpace(.zero)
    }
    
    public static func ==(lhs: AsVectorSpace<X>, rhs: AsVectorSpace<X>) -> Bool {
        return lhs.value == rhs.value
    }
    
    public static func +(a: AsVectorSpace<X>, b: AsVectorSpace<X>) -> AsVectorSpace<X> {
        return AsVectorSpace(a.value + b.value)
    }
    
    public static prefix func -(x: AsVectorSpace<X>) -> AsVectorSpace<X> {
        return AsVectorSpace(-x.value)
    }
    
    public static func *(m: AsVectorSpace<X>, r: X) -> AsVectorSpace<X> {
        return AsVectorSpace(m.value * r)
    }
    
    public static func *(r: X, m: AsVectorSpace<X>) -> AsVectorSpace<X> {
        return AsVectorSpace(r * m.value)
    }
    
    public var hashValue: Int {
        return value.hashValue
    }
    
    public var description: String {
        return value.description
    }
}

public protocol _LinearMap: _ModuleHom, VectorSpace where Domain: VectorSpace, Codomain: VectorSpace { }

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

public protocol _LinearEnd: _LinearMap, End, LieAlgebra {}

public extension _LinearEnd {
    public func bracket(_ g: Self) -> Self {
        let f = self
        return f ∘ g - g ∘ f
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

public protocol _BilinearMap: Map, VectorSpace where Domain == ProductVectorSpace<Left, Right>, Domain.CoeffRing == Codomain.CoeffRing {
    associatedtype Left
    associatedtype Right
    init(_ f: @escaping (Left, Right) -> Codomain)
    subscript(x: Left, y: Right) -> Codomain { get }
}

public extension _BilinearMap {
    public init(_ f: @escaping (Left, Right) -> Codomain) {
        self.init{ (v: ProductVectorSpace) in f(v._1, v._2) }
    }
    
    public subscript(x: Left, y: Right) -> Codomain {
        return self.applied(to: ProductVectorSpace(x, y))
    }
}

public struct BilinearMap<V1: VectorSpace, V2: VectorSpace, W: VectorSpace>: _BilinearMap where V1.CoeffRing == V2.CoeffRing, V1.CoeffRing == W.CoeffRing {
    public typealias R = V1.CoeffRing
    public typealias CoeffRing = R
    public typealias Left = V1
    public typealias Right = V2
    public typealias Domain = ProductVectorSpace<V1, V2>
    public typealias Codomain = W

    private let f: (ProductVectorSpace<V1, V2>) -> W
    public init(_ f: @escaping (ProductVectorSpace<V1, V2>) -> W) {
        self.f = f
    }
    
    public func applied(to v: ProductVectorSpace<V1, V2>) -> W {
        return f(v)
    }
    
    public static func +(a: BilinearMap<V1, V2, W>, b: BilinearMap<V1, V2, W>) -> BilinearMap<V1, V2, W> {
        return BilinearMap { (v: ProductVectorSpace) in a.f(v) + b.f(v) }
    }
    
    public static prefix func -(a: BilinearMap<V1, V2, W>) -> BilinearMap<V1, V2, W> {
        return BilinearMap { (v: ProductVectorSpace) in -a.f(v) }
    }
    
    public static func *(r: R, a: BilinearMap<V1, V2, W>) -> BilinearMap<V1, V2, W> {
        return BilinearMap { (v: ProductVectorSpace) in r * a.f(v) }
    }
    
    public static func *(a: BilinearMap<V1, V2, W>, r: R) -> BilinearMap<V1, V2, W> {
        return BilinearMap { (v: ProductVectorSpace) in a.f(v) * r }
    }
    
    public static var zero: BilinearMap<V1, V2, W> {
        return BilinearMap{ (v1, v2) in .zero }
    }
}

public typealias BilinearForm<V: VectorSpace> = BilinearMap<V, V, AsVectorSpace<V.CoeffRing>>

public extension BilinearForm where V1 == V2, W == AsVectorSpace<V1.CoeffRing> {
    public init(_ f: @escaping (Left, Right) -> R) {
        self.init{ (v: ProductVectorSpace) in AsVectorSpace( f(v._1, v._2) ) }
    }
}

public extension BilinearForm where V1: FiniteDimVectorSpace, V1 == V2, W == AsVectorSpace<V1.CoeffRing> {
    public var asMatrix: DynamicMatrix<R> {
        let n = V1.dim
        let basis = V1.standardBasis
        
        return DynamicMatrix(rows: n, cols: n) { (i, j) in
            let (v, w) = (basis[i], basis[j])
            return self[v, w].value
        }
    }
}
