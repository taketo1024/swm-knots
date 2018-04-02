//
//  BilinearMap.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _BilinearMap: Map, VectorSpace where Left: VectorSpace, Right: VectorSpace, Domain == ProductVectorSpace<Left, Right>, Codomain: VectorSpace, CoeffRing == Left.CoeffRing, Left.CoeffRing == Right.CoeffRing, Domain.CoeffRing == Codomain.CoeffRing {
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
