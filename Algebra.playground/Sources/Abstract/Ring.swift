import Foundation

public protocol Ring: Equatable {
    init(_ intValue: Int)
    static func +(lhs: Self, rhs: Self) -> Self
    prefix static func -(x: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
}
