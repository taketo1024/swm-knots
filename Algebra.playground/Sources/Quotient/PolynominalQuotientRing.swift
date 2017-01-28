import Foundation

public protocol PolynominalIdeal: EuclideanPrincipalIdeal {
    associatedtype R = PolynominalType
}

public struct PolynominalQuotient<K: Field, P: PolynominalIdeal>: EuclideanQuotientRing where P.R == Polynominal<K> {
    public typealias I = P
    public typealias R = Polynominal<K>
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

public struct PolynominalQuotientField <K: Field, P: PolynominalIdeal>: EuclideanQuotientRing, Field where P.R == Polynominal<K> {
    public typealias I = P
    public typealias R = Polynominal<K>
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
    
    public var inverse: PolynominalQuotientField<K, P> {
        let (f, m) = (value, mod)
        
        // find: f * p + m * q = r (r: const)
        // then: f^-1 = r^-1 * p (mod m)
        
        let (p, _, r) = bezout(f, mod)
        if r == 0 || r.degree > 0 {
            fatalError("\(f) and \(m) is not coprime.")
        }
        
        return PolynominalQuotientField(r[0].inverse * p)
    }
}

