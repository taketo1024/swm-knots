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

public func gcd<T: EuclideanRing>(a: T, _ b: T) -> T {
    switch b {
    case T(0):
        return a
    default:
        return gcd(b, a % b)
    }
}

public func bezout<T: EuclideanRing>(a: T, _ b: T) -> (x: T, y: T, r: T) {
    typealias M = Matrix<T, TPInt_2, TPInt_2>
    
    func euclid(a: T, _ b: T, _ qs: [T]) -> (qs: [T], r: T) {
        switch b {
        case T(0):
            return (qs, a)
        default:
            let (q, r) = a /% b
            return euclid(b, r, [q] + qs)
        }
    }
    
    let (qs, r) = euclid(a, b, [])
    
    let m = qs.reduce(M.identity) { (m: M, q: T) -> M in
        m * M(T(0), T(1), T(1), -q)
    }
    
    return (x: m[0, 0], y: m[0, 1], r: r)
}

