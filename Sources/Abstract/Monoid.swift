import Foundation

precedencegroup ExponentiativePrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator **: ExponentiativePrecedence

public protocol Monoid: Equatable, Hashable {
    static func * (a: Self, b: Self) -> Self
    static var identity: Self { get }
    static var symbol: String { get }
}

public extension Monoid {
    public static var symbol: String {
        return "\(Self.self)"
    }
    
    public static func ** (a: Self, b: Int) -> Self {
        return b == 0 ? Self.identity : a * (a ** (b - 1))
    }
}
