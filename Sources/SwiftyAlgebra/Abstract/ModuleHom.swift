//
//  ModuleHom.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _ModuleHom: _AdditiveGroupHom, Module where Domain: Module, Codomain : Module, CoeffRing == Domain.CoeffRing, CoeffRing == Codomain.CoeffRing {}

public extension _ModuleHom {
    public static func *(r: CoeffRing, f: Self) -> Self {
        return Self { x in r * f.applied(to: x) }
    }
    
    public static func *(f: Self, r: CoeffRing) -> Self {
        return Self { x in f.applied(to: x) * r }
    }
    
    public static var symbol: String {
        return "Hom_\(CoeffRing.symbol)(\(Domain.symbol), \(Codomain.symbol))"
    }
}

public struct ModuleHom<X: Module, Y: Module>: _ModuleHom where X.CoeffRing == Y.CoeffRing {
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
    
    public func composed<W>(with f: ModuleHom<W, X>) -> ModuleHom<W, Y> {
        return ModuleHom<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<Z>(g: ModuleHom<Y, Z>, f: ModuleHom<X, Y>) -> ModuleHom<X, Z> {
        return g.composed(with: f)
    }
}
