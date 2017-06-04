//
//  BasicTypes.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/05.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol AlgebraicType: Equatable, Hashable, CustomStringConvertible {
    static var symbol: String { get }
}

public protocol SubAlgebraicType: AlgebraicType {
    associatedtype Super: AlgebraicType
    init(_ g: Super)
    var asSuper: Super { get }
    static func contains(_ g: Super) -> Bool
}

public extension SubAlgebraicType {
    public static func == (a: Self, b: Self) -> Bool {
        return a.asSuper == b.asSuper
    }
    
    public var hashValue: Int {
        return asSuper.hashValue
    }
    
    public var description: String {
        return asSuper.description
    }
}

public protocol ProductAlgebraicType: AlgebraicType {
    associatedtype Left: AlgebraicType
    associatedtype Right: AlgebraicType
    var _1: Left  { get }
    var _2: Right { get }
}

public extension ProductAlgebraicType {
    public static func == (a: Self, b: Self) -> Bool {
        return (a._1 == b._1) && (a._2 == b._2)
    }
    
    public var hashValue: Int {
        return (_1.hashValue &* 31) &+ _2.hashValue
    }
    
    public var description: String {
        return "(\(_1), \(_2))"
    }
    
    public static var symbol: String {
        return "\(Left.symbol)×\(Right.symbol)"
    }
}

public protocol QuotientAlgebraicType: AlgebraicType {
    associatedtype Sub: SubAlgebraicType
    typealias Base = Sub.Super
    
    init(_ g: Base)
    var representative: Base { get }
}

public extension QuotientAlgebraicType {
    public static var symbol: String {
        return "\(Base.symbol)/\(Sub.symbol)"
    }
    
    public var description: String {
        return "[\(representative)]"
    }
}

public protocol FiniteType: AlgebraicType {
    static var allElements: [Self] { get }
    static var countElements: Int { get }
}
