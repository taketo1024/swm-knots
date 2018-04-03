//
//  MonoidHom.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _MonoidHom: MapType where Domain: Monoid, Codomain: Monoid {}

public struct MonoidHom<X: Monoid, Y: Monoid>: _MonoidHom {
    public typealias Domain = X
    public typealias Codomain = Y
    
    private let f: (X) -> Y
    public init(_ f: @escaping (X) -> Y) {
        self.f = f
    }
    
    public func applied(to x: X) -> Y {
        return f(x)
    }
    
    public func composed<W>(with f: MonoidHom<W, X>) -> MonoidHom<W, Y> {
        return MonoidHom<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<Z>(g: MonoidHom<Y, Z>, f: MonoidHom<X, Y>) -> MonoidHom<X, Z> {
        return g.composed(with: f)
    }
}
