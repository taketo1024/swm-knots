import Foundation

public protocol Ring: IntegerLiteralConvertible, Equatable {
    static func zero() -> Self
    static func one() -> Self
    static func +(lhs: Self, rhs: Self) -> Self
    prefix static func -(x: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
}

public extension Ring {
    static func zero() -> Self {
        return Self.init(integerLiteral: 0 as! Self.IntegerLiteralType)
    }
    
    static func one() -> Self {
        return Self.init(integerLiteral: 1 as! Self.IntegerLiteralType)
    }
}

