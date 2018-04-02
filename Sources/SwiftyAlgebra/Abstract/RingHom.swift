//
//  RingHom.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _RingHom: Map where Domain: Ring, Codomain: Ring {}

public struct RingHom<X: Ring, Y: Ring>: _RingHom {
    public typealias Domain = X
    public typealias Codomain = Y
    
    private let f: (X) -> Y
    public init(_ f: @escaping (X) -> Y) {
        self.f = f
    }
    
    public func applied(to x: X) -> Y {
        return f(x)
    }
    
    public func composed<W>(with f: RingHom<W, X>) -> RingHom<W, Y> {
        return RingHom<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<Z>(g: RingHom<Y, Z>, f: RingHom<X, Y>) -> RingHom<X, Z> {
        return g.composed(with: f)
    }
}
