//
//  DynamicType.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/04.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol DynamicType: AlgebraicType {
    var factory: DynamicTypeFactory<Self>? { get }
}

public class DynamicTypeFactory<Type: DynamicType>: Equatable, CustomStringConvertible {
    public func contains(_ g: Type) -> Bool {
        fatalError("implement in subclass.")
    }
    
    public static func == (t1: DynamicTypeFactory<Type>, t2: DynamicTypeFactory<Type>) -> Bool {
        return type(of: t1) == type(of: t2)
    }
    
    public var description: String {
        return "\(type(of: self))"
    }
}

public protocol DynamicSubtype: DynamicType, SubAlgebraicType {
    init(_ g: Self.Super, factory: DynamicTypeFactory<Self>?)
    var asSuper: Super { get }
}

public extension DynamicSubtype {
    internal static func typeMatches(_ a: Self, _ b: Self) -> Bool {
        return (a.factory == b.factory || a.factory == nil || b.factory == nil)
    }
    
    public init(_ g: Super) {
        self.init(g, factory: nil)
    }
    
    public static func == (a: Self, b: Self) -> Bool {
        return a.asSuper == b.asSuper && typeMatches(a, b)
    }
    
    public var hashValue: Int {
        return asSuper.hashValue
    }
    
    public var description: String {
        return "\(asSuper)"
    }
}

public class DynamicSubtypeFactory<Sub: DynamicSubtype>: DynamicTypeFactory<Sub> {
    public typealias Super = Sub.Super
    
    public func asSub(_ g: Super) -> Sub {
        if !self.contains(g) {
            fatalError("\(Sub.self) does not contain element: \(g)")
        }
        return Sub.init(g, factory: self)
    }
    
    public func contains(_ g: Super) -> Bool {
        fatalError("implement in subclass.")
    }
}
