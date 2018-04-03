//
//  Representation.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/23.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol Representation: MapType {
    associatedtype BaseVectorSpace: VectorSpace
}

public protocol _GroupRepresentation: Representation, _GroupHom where Codomain == LinearAut<BaseVectorSpace> { }

public struct GroupRepresentation<G: Group, V: VectorSpace>: _GroupRepresentation {
    public typealias Domain   = G
    public typealias Codomain = LinearAut<V>
    public typealias BaseVectorSpace = V
    
    private let f: (G) -> LinearAut<V>
    public init(_ f: @escaping (G) -> LinearAut<V>) {
        self.f = f
    }
    
    public subscript(g: G) -> LinearAut<V> {
        return f(g)
    }
    
    public func applied(to g: G) -> LinearAut<V> {
        return f(g)
    }
}
