//
//  FreeModuleBase.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol FreeModuleBase: SetType {
    var degree: Int { get }
}

public extension FreeModuleBase {
    public var degree: Int { return 1 }
}

// Default Bases
extension Int:    FreeModuleBase { }
extension String: FreeModuleBase { }

// Derived Bases
public struct Dual<A: FreeModuleBase>: FreeModuleBase {
    public let base: A
    public init(_ a: A) {
        base = a
    }
    
    public var degree: Int {
        return base.degree
    }
    
    public var hashValue: Int {
        return base.hashValue
    }
    
    public func pair(_ s: A) -> Int {
        return (base == s) ? 1 : 0
    }
    
    public static func ==(a: Dual<A>, b: Dual<A>) -> Bool {
        return a.base == b.base
    }
    
    public var description: String {
        return "\(base)*"
    }
}

public enum Sum<A: FreeModuleBase, B: FreeModuleBase>: FreeModuleBase {
    case _1(_: A)
    case _2(_: B)
    
    public var degree: Int {
        switch self {
        case let ._1(a): return a.degree
        case let ._2(b): return b.degree
        }
    }
    
    public var hashValue: Int {
        switch self {
        case let ._1(a): return a.hashValue
        case let ._2(b): return b.hashValue
        }
    }
    
    public static func ==(s1: Sum<A, B>, s2: Sum<A, B>) -> Bool {
        switch (s1, s2) {
        case let (._1(a1), ._1(a2)): return a1 == a2
        case let (._2(b1), ._2(b2)): return b1 == b2
        default: return false
        }
    }
    
    public var description: String {
        switch self {
        case let ._1(a): return a.description
        case let ._2(b): return b.description
        }
    }
}

// Tensor Product
public struct Tensor<A: FreeModuleBase, B: FreeModuleBase>: FreeModuleBase {
    public let _1: A
    public let _2: B
    public init(_ a: A, _ b: B) {
        _1 = a
        _2 = b
    }
    
    public var degree: Int {
        return _1.degree + _2.degree
    }
    
    public var hashValue: Int {
        return _1.hashValue &* 31 &+ _2.hashValue % 31
    }
    
    public static func ==(t1: Tensor<A, B>, t2: Tensor<A, B>) -> Bool {
        return t1._1 == t2._1 && t1._2 == t2._2
    }
    
    public var description: String {
        return "\(_1)⊗\(_2)"
    }
}

public func ⊗<A, B>(a: A, b: B) -> Tensor<A, B> {
    return Tensor(a, b)
}
