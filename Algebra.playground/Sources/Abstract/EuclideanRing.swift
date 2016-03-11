import Foundation

public protocol EuclideanRing: Ring {
    var degree: Int {get}
    func euclideanDiv(rhs: Self) -> (q: Self, r: Self)
    static func /(lhs: Self, rhs: Self) -> Self
    static func %(lhs: Self, rhs: Self) -> Self
}

infix operator /% { associativity left precedence 150 }
public func /%<T: EuclideanRing>(lhs: T, rhs: T) -> (q: T, r: T) {
    return lhs.euclideanDiv(rhs)
}

public func gcd<T: EuclideanRing>(x: T, _ y: T) -> T {
    switch x {
    case T(0):
        return y
    default:
        return gcd(y % x, x)
    }
}

public func euclideanAlgorithm<T: EuclideanRing>(x: T, _ y: T) -> (q0: T, q1: T, r: T) {
    func gcd(x: T, _ y: T, _ q: [T]) -> (q: [T], r: T) {
        switch x {
        case T(0):
            return (q, y)
        default:
            let res = y /% x
            return gcd(res.r, x, [res.q] + q)
        }
    }
    
    let result = gcd(x, y, [])
    
    typealias M = Matrix<T, TPInt_2, TPInt_2>
    let m = result.q.reduce(M.identity) { (m: M, q: T) -> M in
        m * M(-q, T(1), T(1), T(0))
    }
    
    return (q0: m[1, 0], q1: m[1, 1], r: result.r)
}

