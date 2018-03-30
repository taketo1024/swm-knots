import Foundation

// TODO common implementation among all polynomial types...

public struct LaurentPolynomial<K: Field>: Ring, Module {
    public typealias CoeffRing = K
    
    internal let coeffs: [K]
    public let lowerDegree: Int
    
    public init(from n: 𝐙) {
        let a = K(from: n)
        self.init(a)
    }
    
    public init(lowerDegree: Int, coeffs: [K]) {
        assert(coeffs.count > 0)
        
        func normalized(_ d: Int, _ coeffs: [K]) -> (Int, [K]) {
            if coeffs.count == 0 {
                return (d, [.zero])
            } else if coeffs.first! == .zero {
                let dropped = coeffs.drop{ $0 == .zero}.toArray()
                return normalized(d + (coeffs.count - dropped.count), dropped)
            } else if coeffs.last! == .zero {
                let dropped = coeffs.dropLast{ $0 == .zero}.toArray()
                return normalized(d , dropped)
            } else {
                return (d, coeffs)
            }
        }
        
        (self.lowerDegree, self.coeffs) = normalized(lowerDegree, coeffs)
    }
    
    public init(_ coeffs: K...) {
        self.init(lowerDegree: 0, coeffs: coeffs)
    }
    
    public init(lowerDegree: Int, upperDegree: Int, gen: ((Int) -> K)) {
        let coeffs = (lowerDegree ... upperDegree).map(gen)
        self.init(lowerDegree: lowerDegree, coeffs: coeffs)
    }
    
    public var normalizeUnit: LaurentPolynomial<K> {
        return LaurentPolynomial(leadCoeff.inverse!)
    }
    
    public var upperDegree: Int {
        return lowerDegree + coeffs.count - 1
    }
    
    public var span: Int {
        return upperDegree - lowerDegree
    }
    
    public var inverse: LaurentPolynomial<K>? {
        if span == 0, let a = leadCoeff.inverse {
            return LaurentPolynomial(lowerDegree: -lowerDegree, coeffs: [a])
        } else {
            return nil
        }
    }
    
    public var leadCoeff: K {
        return coeff(upperDegree)
    }
    
    public func coeff(_ i: Int) -> K {
        return (lowerDegree ... upperDegree).contains(i) ? coeffs[i - lowerDegree] : .zero
    }
    
    public func mapCoeffs(_ f: ((K) -> K)) -> LaurentPolynomial<K> {
        return LaurentPolynomial(lowerDegree: lowerDegree, coeffs: coeffs.map(f))
    }
    
    public static var indeterminate: LaurentPolynomial<K> {
        return LaurentPolynomial<K>(0, 1)
    }
    
    public static func == (f: LaurentPolynomial<K>, g: LaurentPolynomial<K>) -> Bool {
        return (f.lowerDegree == g.lowerDegree) && f.coeffs == g.coeffs
    }
    
    public static func + (f: LaurentPolynomial<K>, g: LaurentPolynomial<K>) -> LaurentPolynomial<K> {
        let (d, D) = (min(f.lowerDegree, g.lowerDegree), max(f.upperDegree, g.upperDegree))
        return LaurentPolynomial(lowerDegree: d, upperDegree: D) { f.coeff($0) + g.coeff($0) }
    }
    
    public static prefix func - (f: LaurentPolynomial<K>) -> LaurentPolynomial<K> {
        return f.mapCoeffs { -$0 }
    }
    
    public static func * (f: LaurentPolynomial<K>, g: LaurentPolynomial<K>) -> LaurentPolynomial<K> {
        let (d, D) = (f.lowerDegree + g.lowerDegree, f.upperDegree + g.upperDegree)
        return LaurentPolynomial(lowerDegree: d, upperDegree: D) { k in
            (max(f.lowerDegree, k - g.upperDegree) ... min(k - g.lowerDegree, f.upperDegree)).sum {
                f.coeff($0) * g.coeff(k - $0)
            }
        }
    }
    
    public static func * (r: K, f: LaurentPolynomial<K>) -> LaurentPolynomial<K> {
        return f.mapCoeffs { r * $0 }
    }
    
    public static func * (f: LaurentPolynomial<K>, r: K) -> LaurentPolynomial<K> {
        return f.mapCoeffs { $0 * r }
    }
    
    public var description: String {
        return Format.terms("+", (lowerDegree ... upperDegree).map{ i in (coeff(i), "x", i)}, skipZero: true)
    }
    
    public static var symbol: String {
        return "\(K.symbol)[x, x⁻¹]"
    }
    
    public var hashValue: Int {
        return leadCoeff.hashValue
    }
}
