import Foundation

public protocol PolynomialType: Ring, CustomStringConvertible {
    associatedtype R: Ring
    
    init(_ value: Int)
    init(_ coeffs: [R])
    init(_ coeffs: R...)
    init(degree: Int, gen: ((Int) -> R))
    
    var degree: Int {get}
    
    var coeffs: [R] {get}
    var leadCoeff: R {get}
    func coeff(_ i: Int) -> R
    
    func apply(_ x: R) -> R
    func map(_ f: ((R) -> R)) -> Self
    var derivative: Self {get}
}

public extension PolynomialType {
    public init(_ value: Int) {
        let a = R(value)
        self.init([a])
    }
    
    public init(_ coeffs: R...) {
        self.init(coeffs)
    }
    
    public init(degree: Int, gen: ((Int) -> R)) {
        let coeffs = (0 ... degree).map(gen)
        self.init(coeffs)
    }
    
    public var degree: Int {
        let n = coeffs.count - 1
        for i in 0 ..< n {
            if coeffs[n - i] != 0 {
                return n - i
            }
        }
        return 0
    }
    
    public var leadCoeff: R {
        return coeffs[degree]
    }
    
    public func coeff(_ i: Int) -> R {
        return i < coeffs.count ? coeffs[i] : 0
    }
    
    public func apply(_ x: R) -> R {
        return (0 ... degree).reduce(0) { (sum, i) -> R in
            sum + (coeffs[i] * (x ** i))
        }
    }
    
    public func map(_ f: ((R) -> R)) -> Self {
        return Self.init(coeffs.map(f))
    }
    
    public var derivative: Self {
        return Self.init(degree: degree - 1) {
            R($0 + 1) * coeff($0 + 1)
        }
    }
}

extension PolynomialType {
    static public func ==(f: Self, g: Self) -> Bool {
        return (f.degree == g.degree) &&
            (0 ... f.degree).reduce(true) { $0 && (f.coeff($1) == g.coeff($1)) }
    }
    
    static public func +(f: Self, g: Self) -> Self {
        return Self(degree: max(f.degree, g.degree)) { f.coeff($0) + g.coeff($0) }
    }
    
    static public prefix func -(f: Self) -> Self {
        return f.map { -$0 }
    }
    
    static public func *(f: Self, g: Self) -> Self {
        return Self(degree: f.degree + g.degree) {
            (k: Int) in
            (max(0, k - g.degree) ... min(k, f.degree)).reduce(0) {
                (res:R, i:Int) in res + f.coeff(i) * g.coeff(k - i)
            }
        }
    }
}

extension PolynomialType {
    public var description: String {
        let res = coeffs.enumerated().flatMap {
            (n: Int, a: R) -> String? in
            switch(a, n) {
            case ( 0, _): return nil
            case ( _, 0): return "\(a)"
            case ( 1, 1): return "x"
            case (-1, 1): return "-x"
            case ( _, 1): return "\(a)x"
            case ( 1, _): return "x^\(n)"
            case (-1, _): return "-x^\(n)"
            default: return "\(a)x^\(n)"
            }
            }.reversed().joined(separator: " + ")
        return res.isEmpty ? "0" : res
    }
}

// concrete Polynomial-type over a field

public struct Polynomial<K: Field>: PolynomialType, EuclideanRing {
    public typealias R = K
    
    public let coeffs: [K]
    public init(_ coeffs: [K]) {
        self.coeffs = coeffs
    }
    
    public func toMonic() -> Polynomial<K> {
        let a = leadCoeff
        return self.map{ $0 / a }
    }
    
    public static func eucDiv<K: Field>(_ f: Polynomial<K>, _ g: Polynomial<K>) -> (q: Polynomial<K>, r: Polynomial<K>) {
        if g == 0 {
            fatalError("divide by 0")
        }
        
        func eucDivMonomial(_ f: Polynomial<K>, _ g: Polynomial<K>) -> (q: Polynomial<K>, r: Polynomial<K>) {
            let n = f.degree - g.degree
            
            if n < 0 {
                return (0, f)
            } else {
                let a = f.leadCoeff / g.leadCoeff
                let q = Monomial(degree: n, coeff: a)
                let r = f - q * g
                return (q, r)
            }
        }
        
        return (0 ... max(0, f.degree - g.degree))
            .reversed()
            .reduce( (0, f) ) { (result: (Polynomial<K>, Polynomial<K>), degree: Int) in
                let (q, r) = result
                let m = eucDivMonomial(r, g)
                return (q + m.q, m.r)
        }
    }
}

public func Monomial<K>(degree d: Int, coeff a: K) -> Polynomial<K> {
    return Polynomial(degree: d) { $0 == d ? a : 0 }
}

// Concrete Polynomial-type over a ring

public struct RingPolynomial<_R: Ring>: PolynomialType {
    public typealias R = _R
    public let coeffs: [_R]
    public init(_ coeffs: [_R]) {
        self.coeffs = coeffs
    }
}
