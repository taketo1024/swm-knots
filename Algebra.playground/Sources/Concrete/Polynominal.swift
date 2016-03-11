import Foundation

public struct Polynominal<K: Field> {
    private let coeffs: [K]
    public let degree: Int
    
    public init(_ value: Int) {
        let k = K(value)
        self.init(coeffs: [k])
    }
    
    public init(_ descending: K...) {
        self.init(coeffs: descending.reverse())
    }
    
    public init(degree: Int, gen: (Int -> K)) {
        let coeffs = (0 ... degree).map(gen)
        self.init(coeffs: coeffs)
    }
    
    private init(coeffs: [K]) {
        self.coeffs = coeffs
        self.degree = {
            let n = coeffs.count - 1
            return n - (coeffs.reverse().indexOf{$0 != K(0)} ?? n)
            }()
    }
    
    public func coeff(n: Int) -> K {
        return n <= degree ? coeffs[n] : K(0)
    }
    
    public var leadCoeff: K {
        return coeff(degree)
    }
    
    public func toMonic() -> Polynominal<K> {
        let a = leadCoeff
        return (a == K(0)) ? 0 : (K(1) / a) * self
    }
}

public func Monomial<K>(coeff a: K, degree d: Int) -> Polynominal<K> {
    return Polynominal(degree: d) { $0 == d ? a : K(0) }
}

extension Polynominal: Ring {
    public func map(f: (K -> K)) -> Polynominal<K> {
        return Polynominal<K>(coeffs: coeffs.map(f))
    }
    
    public func produceWith(p: Polynominal<K>, f: ((K, K) -> K)) -> Polynominal<K> {
        let deg = max(degree, p.degree)
        let merged = (0 ... deg).map { f(coeff($0), p.coeff($0)) }
        return Polynominal<K>(coeffs: merged)
    }
}

public func ==<K: Field>(lhs: Polynominal<K>, rhs: Polynominal<K>) -> Bool {
    return (lhs.degree == rhs.degree) &&
        (0 ... lhs.degree).reduce(true) { $0 && (lhs.coeff($1) == rhs.coeff($1)) }
}

public func +<K: Field>(lhs: Polynominal<K>, rhs: Polynominal<K>) -> Polynominal<K> {
    return lhs.produceWith(rhs) { $0 + $1 }
}

public prefix func -<K: Field>(lhs: Polynominal<K>) -> Polynominal<K> {
    return lhs.map { -$0 }
}

public func -<K: Field>(lhs: Polynominal<K>, rhs: Polynominal<K>) -> Polynominal<K> {
    return lhs.produceWith(rhs) { $0 - $1 }
}

public func *<K: Field>(a: K, f: Polynominal<K>) -> Polynominal<K> {
    return f.map{ a * $0 }
}

public func *<K: Field>(lhs: Polynominal<K>, rhs: Polynominal<K>) -> Polynominal<K> {
    return Polynominal(degree: lhs.degree + rhs.degree) {
        (n: Int) in
        (0 ... n).reduce(K(0)) {
            $0 + lhs.coeff($1) * rhs.coeff(n - $1)
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

extension Polynominal: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
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