import Foundation

public protocol Ring: Equatable {
    init(_ intValue: Int)
    static func +(lhs: Self, rhs: Self) -> Self
    prefix static func -(x: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
    static func ^(lhs: Self, rhs: Int) -> Self
}

public func ^<R: Ring>(lhs: R, rhs: Int) -> R {
    return (rhs == 0) ? R(1) : lhs * (lhs ^ (rhs - 1))
}