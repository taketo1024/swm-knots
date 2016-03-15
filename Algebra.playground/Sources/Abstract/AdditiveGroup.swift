import Foundation

public protocol AdditiveGroup: Equatable {
    static func +(lhs: Self, rhs: Self) -> Self
    prefix static func -(x: Self) -> Self
    static var zero: Self { get }
}

public func -<G: AdditiveGroup>(lhs: G, rhs: G) -> G {
    return (lhs + (-rhs))
}
