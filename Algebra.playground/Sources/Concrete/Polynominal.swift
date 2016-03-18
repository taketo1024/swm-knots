import Foundation

public protocol PolynominalType: EuclideanRing {
    typealias K: Field
}

public struct Polynominal<K_: Field>: PolynominalType {
    public typealias K = K_
    
    private let coeffs: [K]
    
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
    
    public init(degree: Int, gen: (Int -> K)) {
        let coeffs = (0 ... degree).map(gen)
        self.init(coeffs: coeffs)
    }
    
    public subscript(n: Int) -> K {
        return coeffs[n]
    }
    
    public var degree: Int {
        let n = coeffs.count - 1
        for i in 0 ..< n {
            if self[n - i] != 0 {
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
            sum + (self[i] * (x ^ i))
        }
    }
    
    public func map(f: (K -> K)) -> Polynominal<K> {
        return Polynominal<K>(coeffs: coeffs.map(f))
    }
    
    public func toMonic() -> Polynominal<K> {
        let a = leadCoeff
        return map{ $0 / a }
    }
}

public func Monomial<K>(coeff a: K, degree d: Int) -> Polynominal<K> {
    return Polynominal(degree: d) { $0 == d ? a : K(0) }
}

public func ==<K: Field>(lhs: Polynominal<K>, rhs: Polynominal<K>) -> Bool {
    return (lhs.degree == rhs.degree) &&
        (0 ... lhs.degree).reduce(true) { $0 && (lhs[$1] == rhs[$1]) }
}

public func +<K: Field>(lhs: Polynominal<K>, rhs: Polynominal<K>) -> Polynominal<K> {
    return Polynominal<K>(degree: max(lhs.degree, rhs.degree)) { lhs[$0] + rhs[$0] }
}

public prefix func -<K: Field>(lhs: Polynominal<K>) -> Polynominal<K> {
    return lhs.map { -$0 }
}

public func *<K: Field>(a: K, f: Polynominal<K>) -> Polynominal<K> {
    return f.map{ a * $0 }
}

public func *<K: Field>(lhs: Polynominal<K>, rhs: Polynominal<K>) -> Polynominal<K> {
    return Polynominal(degree: lhs.degree + rhs.degree) {
        (n: Int) in
        (0 ... n).reduce(K(0)) {
            $0 + lhs[$1] * rhs[n - $1]
        }
    }
}

extension Polynominal: EuclideanRing {
    public func euclideanDiv(rhs: Polynominal) -> (q: Polynominal, r: Polynominal) {
        guard rhs != 0 else {
            fatalError("divide by 0")
        }
        
        if degree < rhs.degree {
            return (0, self)
        } else {
            return (0 ... degree - rhs.degree)
                .reverse()
                .reduce( (0, self) ) {
                    (res, d: Int) -> (Polynominal<K>, Polynominal<K>) in
                    
                    let g = res.r
                    if g.degree < rhs.degree {
                        return res
                    } else {
                        let q = Monomial(coeff: res.r.leadCoeff / rhs.leadCoeff, degree: d)
                        let r = res.r - q * rhs
                        //print("\(res.r) = \(q) * (\(rhs)) ... \(r)")
                        return (res.q + q, r)
                    }
            }
        }
    }
}

public func /<K: Field>(lhs: Polynominal<K>, rhs: Polynominal<K>) -> Polynominal<K> {
    return lhs.euclideanDiv(rhs).q
}

public func %<K: Field>(lhs: Polynominal<K>, rhs: Polynominal<K>) -> Polynominal<K> {
    return lhs.euclideanDiv(rhs).r
}

extension Polynominal: CustomStringConvertible {
    public var description: String {
        let _0 = K(0)
        let _1 = K(1)
        
        let res = coeffs.enumerate().flatMap {
            (n: Int, a: K) -> String? in
            switch(a, n) {
            case (_0,  _): return nil
            case ( _,  0): return "\(a)"
            case ( _1, 1): return "x"
            case (-_1, 1): return "-x"
            case ( _,  1): return "\(a)x"
            case ( _1, _): return "x^\(n)"
            case (-_1, _): return "-x^\(n)"
            default: return "\(a)x^\(n)"
            }
            }.reverse().joinWithSeparator(" + ")
        return res.isEmpty ? "0" : res
    }
}