import Foundation

public protocol EuclideanRing: Ring {
    var degree: Int { get }
    static func eucDiv(a: Self, _ b: Self) -> (q: Self, r: Self)
    static func %(a: Self, b: Self) -> Self
}

public func %<R: EuclideanRing>(a: R, b: R) -> R {
    return R.eucDiv(a, b).r
}

infix operator /% { associativity left precedence 150 }

public func /%<R: EuclideanRing>(a: R, b: R) -> (q: R, r: R) {
    return R.eucDiv(a, b)
}

public func gcd<R: EuclideanRing>(a: R, _ b: R) -> R {
    switch b {
    case 0:
        return a
    default:
        return gcd(b, a % b)
    }
}

public func bezout<R: EuclideanRing>(a: R, _ b: R) -> (x: R, y: R, r: R) {
    typealias M = Matrix<R, TPInt_2, TPInt_2>
    
    func euclid(a: R, _ b: R, _ qs: [R]) -> (qs: [R], r: R) {
        switch b {
        case 0:
            return (qs, a)
        default:
            let (q, r) = a /% b
            return euclid(b, r, [q] + qs)
        }
    }
    
    let (qs, r) = euclid(a, b, [])
    
    let m = qs.reduce(M.identity) { (m: M, q: R) -> M in
        m * M(0, 1, 1, -q)
    }
    
    return (x: m[0, 0], y: m[0, 1], r: r)
}

