import Foundation

public protocol PolynomialType: EuclideanRing {
    associatedtype K: Field
    func apply(_ x: K) -> K
}

public struct Polynomial<K_: Field>: PolynomialType {
    public typealias K = K_
    
    fileprivate let coeffs: [K]
    
    public init(coeffs: [K]) {
        self.coeffs = coeffs
    }
    
    public init(_ value: Int) {
        let k = K(value)
        self.init(coeffs: [k])
    }
    
    public init(_ coeffs: K...) {
        self.init(coeffs: coeffs)
    }
    
    public init(degree: Int, gen: ((Int) -> K)) {
        let coeffs = (0 ... degree).map(gen)
        self.init(coeffs: coeffs)
    }
    
    public subscript(n: Int) -> K {
        return n <= degree ? coeffs[n] : 0
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
    
    public var leadCoeff: K {
        return self[degree]
    }
    
    public func apply(_ x: K) -> K {
        return (0 ... degree).reduce(0) { (sum, i) -> K in
            sum + (self[i] * (x ** i))
        }
    }
    
    public func map(_ f: ((K) -> K)) -> Polynomial<K> {
        return Polynomial<K>(coeffs: coeffs.map(f))
    }
    
    public func toMonic() -> Polynomial<K> {
        let a = leadCoeff
        return map{ $0 / a }
    }
}

public func Monomial<K>(degree d: Int, coeff a: K) -> Polynomial<K> {
    return Polynomial(degree: d) { $0 == d ? a : 0 }
}

public func == <K: Field>(f: Polynomial<K>, g: Polynomial<K>) -> Bool {
    return (f.degree == g.degree) &&
        (0 ... f.degree).reduce(true) { $0 && (f[$1] == g[$1]) }
}

public func + <K: Field>(f: Polynomial<K>, g: Polynomial<K>) -> Polynomial<K> {
    return Polynomial<K>(degree: max(f.degree, g.degree)) { f[$0] + g[$0] }
}

public prefix func - <K: Field>(f: Polynomial<K>) -> Polynomial<K> {
    return f.map { -$0 }
}

public func * <K: Field>(a: K, f: Polynomial<K>) -> Polynomial<K> {
    return f.map{ a * $0 }
}

public func * <K: Field>(f: Polynomial<K>, g: Polynomial<K>) -> Polynomial<K> {
    return Polynomial(degree: f.degree + g.degree) {
        (n: Int) in
        (0 ... n).reduce(0) {
            $0 + f[$1] * g[n - $1]
        }
    }
}

extension Polynomial: EuclideanRing {
    public static func eucDiv<K: Field>(_ f: Polynomial<K>, _ g: Polynomial<K>) -> (q: Polynomial<K>, r: Polynomial<K>) {
        if g == 0 {
            fatalError("divide by 0")
        }
        
        func eucDivMonomial(_ f: Polynomial<K>, _ g: Polynomial<K>) -> (q: Polynomial<K>, r: Polynomial<K>) {
            let n = f.degree - g.degree
            if n < 0 {
                return (0, f)
            } else {
                let a = f[f.degree] / g[g.degree]
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

extension Polynomial: CustomStringConvertible {
    public var description: String {
        let res = coeffs.enumerated().flatMap {
            (n: Int, a: K) -> String? in
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
