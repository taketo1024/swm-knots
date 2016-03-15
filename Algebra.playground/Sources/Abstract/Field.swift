import Foundation

public protocol Field: Group, Ring {
}

public func /<F: Field>(lhs: F, rhs: F) -> F {
    return lhs * rhs.inverse
}
