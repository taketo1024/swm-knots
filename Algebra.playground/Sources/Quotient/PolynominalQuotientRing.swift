import Foundation

public protocol PolynomialIdeal: EuclideanPrincipalIdeal {
    associatedtype R = PolynomialType
}

public struct PolynomialQuotient<K: Field, P: PolynomialIdeal>: EuclideanQuotientRing where P.R == Polynomial<K> {
    public typealias I = P
    public typealias R = Polynomial<K>
    public let value: R
    
    public init(_ value: Int) {
        self.value = R(value)
    }
    
    public init(_ coeffs: K...) {
        self.value = R(coeffs: coeffs)
    }
    
    public init(_ value: R) {
        self.value = value
    }
}

public struct PolynomialQuotientField <K: Field, P: PolynomialIdeal>: EuclideanQuotientRing, Field where P.R == Polynomial<K> {
    public typealias I = P
    public typealias R = Polynomial<K>
    public let value: R
    
    public init(_ value: Int) {
        self.value = R(value)
    }
    
    public init(_ coeffs: K...) {
        self.value = R(coeffs: coeffs)
    }
    
    public init(_ value: R) {
        self.value = value
    }
    
    public var inverse: PolynomialQuotientField<K, P> {
        let (f, m) = (value, mod)
        
        // find: f * p + m * q = r (r: const)
        // then: f^-1 = r^-1 * p (mod m)
        
        let (p, _, r) = bezout(f, mod)
        if r == 0 || r.degree > 0 {
            fatalError("\(f) and \(m) is not coprime.")
        }
        
        return PolynomialQuotientField(r[0].inverse * p)
    }
}

