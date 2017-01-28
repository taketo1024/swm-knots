import Foundation

public protocol PolynominalType: EuclideanRing {
    associatedtype K: Field
}

public struct Polynominal<K_: Field>: PolynominalType {
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
    
    public func apply(x: K) -> K {
        return (0 ... degree).reduce(0) { (sum, i) -> K in
            sum + (self[i] * (x ** i))
        }
    }
    
    public func map(f: ((K) -> K)) -> Polynominal<K> {
        return Polynominal<K>(coeffs: coeffs.map(f))
    }
    
    public func toMonic() -> Polynominal<K> {
        let a = leadCoeff
        return map{ $0 / a }
    }
}

public func Monomial<K>(degree d: Int, coeff a: K) -> Polynominal<K> {
    return Polynominal(degree: d) { $0 == d ? a : 0 }
}

public func == <K: Field>(f: Polynominal<K>, g: Polynominal<K>) -> Bool {
    return (f.degree == g.degree) &&
        (0 ... f.degree).reduce(true) { $0 && (f[$1] == g[$1]) }
}

public func + <K: Field>(f: Polynominal<K>, g: Polynominal<K>) -> Polynominal<K> {
    return Polynominal<K>(degree: max(f.degree, g.degree)) { f[$0] + g[$0] }
}

public prefix func - <K: Field>(f: Polynominal<K>) -> Polynominal<K> {
    return f.map { -$0 }
}

public func * <K: Field>(a: K, f: Polynominal<K>) -> Polynominal<K> {
    return f.map{ a * $0 }
}

public func * <K: Field>(f: Polynominal<K>, g: Polynominal<K>) -> Polynominal<K> {
    return Polynominal(degree: f.degree + g.degree) {
        (n: Int) in
        (0 ... n).reduce(0) {
            $0 + f[$1] * g[n - $1]
        }
    }
}

extension Polynominal: EuclideanRing {
    public static func eucDiv<K: Field>(_ f: Polynominal<K>, _ g: Polynominal<K>) -> (q: Polynominal<K>, r: Polynominal<K>) {
        if g == 0 {
            fatalError("divide by 0")
        }
        
        func eucDivMonomial(_ f: Polynominal<K>, _ g: Polynominal<K>) -> (q: Polynominal<K>, r: Polynominal<K>) {
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
            .reduce( (0, f) ) { (result: (Polynominal<K>, Polynominal<K>), degree: Int) in
                let (q, r) = result
                let m = eucDivMonomial(r, g)
                return (q + m.q, m.r)
        }
    }
}

extension Polynominal: CustomStringConvertible {
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
