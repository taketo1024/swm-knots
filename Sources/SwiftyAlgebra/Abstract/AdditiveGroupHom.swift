//
//  AdditiveGroupHom.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _AdditiveGroupHom: MapType, AdditiveGroup where Domain: AdditiveGroup, Codomain: AdditiveGroup {}

public extension _AdditiveGroupHom {
    static var zero: Self {
        return Self { _ in .zero }
    }
    
    public static func + (f: Self, g: Self) -> Self {
        return Self { x in f.applied(to: x) + g.applied(to: x) }
    }
    
    prefix static func - (f: Self) -> Self {
        return Self { x in -f.applied(to: x) }
    }
}

public struct AdditiveGroupHom<X: AdditiveGroup, Y: AdditiveGroup>: _AdditiveGroupHom {
    public typealias Domain = X
    public typealias Codomain = Y
    
    private let f: (X) -> Y
    public init(_ f: @escaping (X) -> Y) {
        self.f = f
    }
    
    public func applied(to x: X) -> Y {
        return f(x)
    }
    
    public func composed<W>(with f: AdditiveGroupHom<W, X>) -> AdditiveGroupHom<W, Y> {
        return AdditiveGroupHom<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<Z>(g: AdditiveGroupHom<Y, Z>, f: AdditiveGroupHom<X, Y>) -> AdditiveGroupHom<X, Z> {
        return g.composed(with: f)
    }
}
