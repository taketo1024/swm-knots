import Foundation

public struct FieldExtension<F: TPPolynominal>: Field {
    typealias K = F.K
    
    let f: Polynominal<K>
    private var g: Polynominal<K> {
        return F.value
    }
    
    public init(_ f: Polynominal<K>) {
        self.f = f
    }
    
    public init(_ n: Integer) {
        self.init(Polynominal<K>(n))
    }
    
    public func reduce() -> FieldExtension<F> {
        return FieldExtension(f % g)
    }
    
    public var inverse: FieldExtension<F> {
        // find: a * f + b * g = r (r: const)
        // then: f^-1 = a / r (mod g)
        
        let res = euclideanAlgorithm(f, g)
        if res.r == 0 || res.r.degree > 0 {
            fatalError("\(f) and \(g) is not coprime.")
        }
        
        return FieldExtension((1 / res.r) * res.q0)
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
    return FieldExtension( (lhs.f * rhs.f) % lhs.g)
}

public func /<F: TPPolynominal>(lhs: FieldExtension<F>, rhs: FieldExtension<F>) -> FieldExtension<F> {
    return (lhs * rhs.inverse).reduce()
}

extension FieldExtension: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(Integer(value))
    }
}

extension FieldExtension: CustomStringConvertible {
    public var description: String {
        return "\(f % g) mod (\(g))"
    }
}
