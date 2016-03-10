import Foundation

public protocol Ring: IntegerLiteralConvertible, Equatable {
    init(_ intValue: Int)
    static var zero: Self {get}
    static var one: Self {get}
    static func +(lhs: Self, rhs: Self) -> Self
    prefix static func -(x: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
}

public extension Ring {
    static var zero: Self {
        return Self.init(integerLiteral: 0 as! Self.IntegerLiteralType)
    }
    
    static var one: Self {
        return Self.init(integerLiteral: 1 as! Self.IntegerLiteralType)
    }
}

