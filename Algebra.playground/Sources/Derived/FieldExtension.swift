import Foundation

public struct FieldExtension<F: TPPolynominal>: Field {
    typealias K = F.K
    
    let f: Polynominal<K>
    private var m: Polynominal<K> {
        return F.value
    }
    
    public init(_ f: Polynominal<K>) {
        self.f = f
    }
    
    public init(_ n: Int) {
        self.init(Polynominal<K>(n))
    }
    
    public init(_ coeffs: K...) {
        self.init(Polynominal<K>(coeffs: coeffs))
    }
    
    public var reduced: FieldExtension<F> {
        return FieldExtension(f % m)
    }
    
    public var inverse: FieldExtension<F> {
        // find: f * p + m * q = r (r: const)
        // then: f^-1 = r^-1 * p (mod m)
        
        let (p, _, r) = bezout(f, m)
        if r == 0 || r.degree > 0 {
            fatalError("\(f) and \(m) is not coprime.")
        }
        
        return FieldExtension((F.K(1) / r.coeff(0)) * p)
    }
}

public func ==<F: TPPolynominal>(lhs: FieldExtension<F>, rhs: FieldExtension<F>) -> Bool {
    return (lhs.f - rhs.f) % F.value == 0
}

public func +<F: TPPolynominal>(lhs: FieldExtension<F>, rhs: FieldExtension<F>) -> FieldExtension<F> {
    return FieldExtension(lhs.f + rhs.f)
}

public prefix func -<F: TPPolynominal>(lhs: FieldExtension<F>) -> FieldExtension<F> {
    return FieldExtension(-lhs.f)
}

public func -<F: TPPolynominal>(lhs: FieldExtension<F>, rhs: FieldExtension<F>) -> FieldExtension<F> {
    return FieldExtension(lhs.f - rhs.f)
}

public func *<F: TPPolynominal>(lhs: FieldExtension<F>, rhs: FieldExtension<F>) -> FieldExtension<F> {
    return FieldExtension( (lhs.f * rhs.f) % lhs.m)
}

public func ^<F: TPPolynominal>(lhs: FieldExtension<F>, rhs: Int) -> FieldExtension<F> {
    return (rhs == 0) ? FieldExtension(1) : lhs * (lhs ^ (rhs - 1)).reduced
}

extension FieldExtension: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(Z(value))
    }
}

extension FieldExtension: CustomStringConvertible {
    public var description: String {
        return "\(f % m) mod (\(m))"
    }
}
