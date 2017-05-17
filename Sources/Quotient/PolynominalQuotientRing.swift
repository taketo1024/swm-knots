import Foundation

public struct PolynomialQuotientRing<K: Field, P: _Polynomial>: EuclideanQuotientRing where K == P.K {
    public typealias R = Polynomial<K>
    public let value: R
    
    // root initializer
    public init(_ value: R) {
        self.value = (value % P.value)
    }
    
    public init(_ value: Int) {
        self.init(R(value))
    }
    
    public init(_ coeffs: K...) {
        self.init(R(coeffs))
    }
    
    public var mod: R {
        return P.value
    }
    
    public static var symbol: String {
        return "\(R.symbol)[x]/\(P.value)"
    }
}

public struct PolynomialQuotientField<K: Field, P: _Polynomial>: EuclideanQuotientField where K == P.K {
    public typealias R = Polynomial<K>
    public let value: R
    
    public init(_ value: R) {
        self.value = (value % P.value)
        
        // TODO check if P is irreducible.
    }
    
    public init(_ value: Int) {
        self.init(R(value))
    }
    
    public init(_ coeffs: K...) {
        self.init(R(coeffs))
    }
    
    public var mod: R {
        return P.value
    }
    
    public var inverse: PolynomialQuotientField<K, P> {
        // find: f * p + m * q = r (r: const)
        // then: f^-1 = r^-1 * p (mod m)
        
        let (p, _, r) = bezout(value, mod)
        if r == 0 || r.degree > 0 {
            fatalError("\(value) and \(mod) is not coprime.")
        }
        
        return PolynomialQuotientField(r.coeff(0).inverse * p)
    }
    
    public static var symbol: String {
        return "\(R.symbol)[x]/\(P.value)"
    }
}
