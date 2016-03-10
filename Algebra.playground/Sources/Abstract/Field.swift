import Foundation

public protocol Field: Ring {
    static func /(lhs: Self, rhs: Self) -> Self
}