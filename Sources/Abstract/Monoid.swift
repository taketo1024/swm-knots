import Foundation

precedencegroup ExponentiativePrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator **: ExponentiativePrecedence

public protocol Monoid: AlgebraicType {
    static func * (a: Self, b: Self) -> Self
    static var identity: Self { get }
}

public extension Monoid {
    public static func ** (a: Self, b: Int) -> Self {
        return b == 0 ? Self.identity : a * (a ** (b - 1))
    }
}
