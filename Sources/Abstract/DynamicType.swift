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

public protocol DynamicQuotientType: DynamicType, QuotientAlgebraicType {
    associatedtype Sub: DynamicSubtype
    init(_ g: Self.Base, factory: DynamicTypeFactory<Self>?)
    var quotientFactory: DynamicQuotientTypeFactory<Self>? { get }
}

public extension DynamicQuotientType {
    public init(_ g: Self.Base) {
        self.init(g, factory: nil)
    }
    
    public var quotientFactory: DynamicQuotientTypeFactory<Self>? {
        if let f = factory as? DynamicQuotientTypeFactory<Self> {
            return f
        }
        return nil
    }
    
    internal static func typeMatches(_ a: Self, _ b: Self) -> Bool {
        return (a.factory == b.factory || a.factory == nil || b.factory == nil)
    }
}

public class DynamicQuotientTypeFactory<Quot: DynamicQuotientType>: DynamicTypeFactory<Quot> {
    public typealias Base = Quot.Base
    public typealias Sub = Quot.Sub
    
    public let subtypeFactory: DynamicSubtypeFactory<Sub>
    
    public init(subtypeFactory: DynamicSubtypeFactory<Sub>) {
        self.subtypeFactory = subtypeFactory
    }
    
    public func asQuotient(_ g: Base) -> Quot {
        return Quot.init(g, factory: self)
    }
    
    public func isEquivalent(_ a: Base, _ b: Base) -> Bool {
        fatalError("override in subclass.")
    }
}
