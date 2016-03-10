import Foundation

public protocol EuclideanRing: Ring {
    var degree: Int {get}
    func div(rhs: Self) -> (q: Self, r: Self)
    static func /(lhs: Self, rhs: Self) -> Self
    static func %(lhs: Self, rhs: Self) -> Self
}

public func gcd<T: EuclideanRing>(x: T, _ y: T) -> T {
    switch(x.degree, y.degree) {
    case (_, 0):
        return x
    case (0, _):
        return y
    case let (a, b) where a >= b:
        return gcd(x % y, y)
    default:
        return gcd(x, y % x)
    }
}