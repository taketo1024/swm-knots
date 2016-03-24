import Foundation

public protocol AdditiveGroup: Equatable {
    static func + (a: Self, b: Self) -> Self
    prefix static func - (x: Self) -> Self
    static var zero: Self { get }
}

public func - <G: AdditiveGroup>(a: G, b: G) -> G {
    return (a + (-b))
}
