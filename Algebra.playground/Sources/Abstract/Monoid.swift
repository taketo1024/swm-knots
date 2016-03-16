import Foundation

public protocol Monoid: Equatable {
    static func *(lhs: Self, rhs: Self) -> Self
    static var identity: Self {get}
    var reduced: Self {get}
}

extension Monoid {
    public var reduced: Self {
        return self
    }
}