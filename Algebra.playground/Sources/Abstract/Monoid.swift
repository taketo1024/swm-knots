import Foundation

public protocol Monoid: Equatable {
    static func * (a: Self, b: Self) -> Self
    static var identity: Self { get }
    var reduced: Self { get }
}

extension Monoid {
    public var reduced: Self {
        return self
    }
}

infix operator ** { associativity left precedence 160 }

public func ** <G: Monoid>(a: G, b: Int) -> G {
    return b == 0 ? G.identity : a * (a ** (b - 1))
}
