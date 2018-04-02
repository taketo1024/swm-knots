//
//  GroupHom.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _GroupHom: _MonoidHom where Domain: Group, Codomain: Group {}

public extension _GroupHom where Domain == Codomain {
    static var identity: Self {
        return Self { x in x }
    }
}

public struct GroupHom<X: Group, Y: Group>: _GroupHom {
    public typealias Domain = X
    public typealias Codomain = Y
    
    private let f: (X) -> Y
    public init(_ f: @escaping (X) -> Y) {
        self.f = f
    }
    
    public func applied(to x: X) -> Y {
        return f(x)
    }
    
    public func composed<W>(with f: GroupHom<W, X>) -> GroupHom<W, Y> {
        return GroupHom<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<Z>(g: GroupHom<Y, Z>, f: GroupHom<X, Y>) -> GroupHom<X, Z> {
        return g.composed(with: f)
    }
}
