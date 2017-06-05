import Foundation

precedencegroup ExponentiativePrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator **: ExponentiativePrecedence

public protocol Monoid: SetType {
    static func * (a: Self, b: Self) -> Self
    static var identity: Self { get }
}

public extension Monoid {
    public static func ** (a: Self, b: Int) -> Self {
        return b == 0 ? Self.identity : a * (a ** (b - 1))
    }
}

public protocol Submonoid: Monoid, SubsetType {
    associatedtype Super: Monoid
}

public extension Submonoid {
    static var identity: Self {
        return Self.init(Super.identity)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self.init(a.asSuper * b.asSuper)
    }
}

public protocol ProductMonoidType: Monoid, ProductSetType {
    associatedtype Left: Monoid
    associatedtype Right: Monoid
}

public extension ProductMonoidType {
    public static var identity: Self {
        return Self.init(Left.identity, Right.identity)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self.init(a._1 * b._1, a._2 * b._2)
    }
}

