import Foundation

infix operator /%: MultiplicationPrecedence

public protocol EuclideanRing: Ring {
    var degree: Int { get }
    static func eucDiv(_ a: Self, _ b: Self) -> (q: Self, r: Self)
    static func % (a: Self, b: Self) -> Self
}

public extension EuclideanRing {
    public var isUnit: Bool {
        return (self != 0) && (1 % self == 0)
    }
    
    public static func % (_ a: Self, b: Self) -> Self {
        return Self.eucDiv(a, b).r
    }
    
    public static func /% (_ a: Self, b: Self) -> (q: Self, r: Self) {
        return Self.eucDiv(a, b)
    }
    
    static func matrixElimination<n:_Int, m:_Int>(_ A: Matrix<Self, n, m>, mode: MatrixEliminationMode) -> BaseMatrixElimination<Self, n, m> {
        return EuclideanMatrixElimination<Self, n, m>(A, mode: mode)
    }
}

public func gcd<R: EuclideanRing>(_ a: R, _ b: R) -> R {
    switch b {
    case 0:
        return a
    default:
        return gcd(b, a % b)
    }
}

public func lcm<R: EuclideanRing>(_ a: R, _ b: R) -> R {
    return R.eucDiv(a * b, gcd(a, b)).q
}

public func bezout<R: EuclideanRing>(_ a: R, _ b: R) -> (x: R, y: R, r: R) {
    typealias M = SquareMatrix<R, _2>
    
    func euclid(_ a: R, _ b: R, _ qs: [R]) -> (qs: [R], r: R) {
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

public protocol EuclideanIdeal: Ideal {
    associatedtype Super: EuclideanRing
    static var generator: Super { get }
}

public extension EuclideanIdeal {
    static func reduced(_ a: Super) -> Super {
        return a % generator
    }
    
    static func contains(_ a: Super) -> Bool {
        return a % generator == Super.zero
    }
    
    static var symbol: String {
        return "\(Super.symbol)(\(generator))"
    }
}

public protocol EuclideanQuotientRingType: QuotientRingType {
    associatedtype Sub: EuclideanIdeal
}

public protocol EuclideanQuotientFieldType: QuotientFieldType, EuclideanQuotientRingType {
}

public extension EuclideanQuotientFieldType {
    public var isUnit: Bool {
        return representative != 0
    }
    
    public var unitInverse: Self? {
        return isUnit ? inverse : nil
    }
    
    public var inverse: Self {
        // find: a * r + b * m = u (u: unit)
        // then: r^-1 = u^-1 * a (mod m)
        let (a, _, u) = bezout(representative, Sub.generator)
        return Self.init(u.unitInverse! * a)
    }
}
