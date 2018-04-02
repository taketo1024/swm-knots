//
//  BasicTypes.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/05.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// MEMO: since `Set` is already used in Foundation.
public protocol SetType: Hashable, CustomStringConvertible {
    var detailDescription: String { get }
    static var symbol: String { get }
}

public extension SetType {
    public var detailDescription: String {
        return description
    }
    
    public static var symbol: String {
        return String(describing: self)
    }
}

public protocol FiniteSet: SetType {
    static var allElements: [Self] { get }
    static var countElements: Int { get }
}

public protocol Subset: SetType {
    associatedtype Super: SetType
    init(_ g: Super)
    var asSuper: Super { get }
    static func contains(_ g: Super) -> Bool
}

public extension Subset {
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

public extension SetType {
    public func asSubset<S: Subset>(of: S.Type) -> S where S.Super == Self {
        assert(S.contains(self), "\(S.self) does not contain \(self).")
        return S.init(self)
    }
}

public protocol _ProductSet: SetType {
    associatedtype Left: SetType
    associatedtype Right: SetType
    var _1: Left  { get }
    var _2: Right { get }
    init(_ a1: Left, _ a2: Right)
}

public extension _ProductSet {
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

public struct ProductSet<S1: SetType, S2: SetType>: _ProductSet {
    public typealias Left = S1
    public typealias Right = S2
    
    public let _1: S1
    public let _2: S2
    
    public init(_ s1: S1, _ s2: S2) {
        self._1 = s1
        self._2 = s2
    }
}

public protocol _QuotientSet: SetType {
    associatedtype Base: SetType
    
    init(_ g: Base)
    var representative: Base { get }
    static func isEquivalent(_ a: Base, _ b: Base) -> Bool
}

public extension _QuotientSet {
    public static func == (a: Self, b: Self) -> Bool {
        return isEquivalent(a.representative, b.representative)
    }

    public var description: String {
        return "\(representative)"
    }
    
    public static var symbol: String {
        return "\(Base.symbol)/~"
    }
}

public extension SetType {
    public func asQuotient<Q: _QuotientSet>(in: Q.Type) -> Q where Q.Base == Self {
        return Q.init(self)
    }
}
