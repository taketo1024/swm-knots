import Foundation

public protocol AdditiveGroup: Equatable {
    static func + (a: Self, b: Self) -> Self
    prefix static func - (x: Self) -> Self
    static var zero: Self { get }
    static var symbol: String { get }
}

public extension AdditiveGroup {
    public static func -(a: Self, b: Self) -> Self {
        return (a + (-b))
    }
}
