import Foundation

public protocol Field: Group, Ring {
}

public func /<F: Field>(a: F, b: F) -> F {
    return a * b.inverse
}
