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

public struct ProductSet<Left: SetType, Right: SetType>: SetType {
    public let left : Left
    public let right: Right
    
    public init(_ x: Left, _ y: Right) {
        self.left  = x
        self.right = y
    }
    
    public static func == (a: ProductSet<Left, Right>, b: ProductSet<Left, Right>) -> Bool {
        return (a.left, a.right) == (b.left, b.right)
    }
    
    public var hashValue: Int {
        return (left.hashValue &* 31) &+ right.hashValue
    }
    
    public var description: String {
        return "(\(left), \(right))"
    }
    
    public static var symbol: String {
        return "\(Left.symbol)×\(Right.symbol)"
    }
}

// MEMO When "parametrized extension" is supported, we could defile:
//
//   struct QuotientSet<X: Base, Rel: EquivalenceRelation>
//
// and override in subtypes as:
//
//   public typealias QuotientGroup<G, H: NormalSubgroup> = QuotientSet<G, ModSubgroupRelation<H>> where G == H.Super
//   extension<H: NormalSubgroup> QuotientGroup where X == H.Super, Rel == ModSubgroupRelation<H> { ... }
//
// see: https://github.com/apple/swift/blob/master/docs/GenericsManifesto.md#parameterized-extensions

public protocol _QuotientSet: SetType {
    associatedtype Base: SetType
    init (_ x: Base)
    var representative: Base { get }
    static func isEquivalent(_ x: Base, _ y: Base) -> Bool
}

public extension _QuotientSet {
    public var description: String {
        return representative.description
    }
    
    public static func == (a: Self, b: Self) -> Bool {
        return isEquivalent(a.representative, b.representative)
    }
    
    public static var symbol: String {
        return "\(Base.symbol)/~"
    }
}
