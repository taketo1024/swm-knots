import Foundation

// TODO common implementation among all polynomial types...

public struct LaurentPolynomial<R: Ring>: Ring, Module {
    public typealias CoeffRing = R
    
    internal let coeffs: [R]
    public let lowerDegree: Int
    
    public init(from n: 𝐙) {
        let a = R(from: n)
        self.init(a)
    }
    
    public init(lowerDegree: Int, coeffs: [R]) {
        assert(coeffs.count > 0)
        
        func normalized(_ d: Int, _ coeffs: [R]) -> (Int, [R]) {
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
    
    public init(_ coeffs: R...) {
        self.init(lowerDegree: 0, coeffs: coeffs)
    }
    
    public init(lowerDegree: Int, upperDegree: Int, gen: ((Int) -> R)) {
        let coeffs = (lowerDegree ... upperDegree).map(gen)
        self.init(lowerDegree: lowerDegree, coeffs: coeffs)
    }
    
    public var normalizeUnit: LaurentPolynomial<R> {
        if let a = leadCoeff.inverse {
            return LaurentPolynomial(a)
        } else {
            return LaurentPolynomial(.identity)
        }
    }
    
    public var upperDegree: Int {
        return lowerDegree + coeffs.count - 1
    }
    
    public var span: Int {
        return upperDegree - lowerDegree
    }
    
    public var inverse: LaurentPolynomial<R>? {
        if span == 0, let a = leadCoeff.inverse {
            return LaurentPolynomial(lowerDegree: -lowerDegree, coeffs: [a])
        } else {
            return nil
        }
    }
    
    public var leadCoeff: R {
        return coeff(upperDegree)
    }
    
    public func coeff(_ i: Int) -> R {
        return (lowerDegree ... upperDegree).contains(i) ? coeffs[i - lowerDegree] : .zero
    }
    
    public func mapCoeffs(_ f: ((R) -> R)) -> LaurentPolynomial<R> {
        return LaurentPolynomial(lowerDegree: lowerDegree, coeffs: coeffs.map(f))
    }
    
    public static var indeterminate: LaurentPolynomial<R> {
        return LaurentPolynomial<R>(.zero, .identity)
    }
    
    public static func == (f: LaurentPolynomial<R>, g: LaurentPolynomial<R>) -> Bool {
        return (f.lowerDegree == g.lowerDegree) && f.coeffs == g.coeffs
    }
    
    public static func + (f: LaurentPolynomial<R>, g: LaurentPolynomial<R>) -> LaurentPolynomial<R> {
        let (d, D) = (min(f.lowerDegree, g.lowerDegree), max(f.upperDegree, g.upperDegree))
        return LaurentPolynomial(lowerDegree: d, upperDegree: D) { f.coeff($0) + g.coeff($0) }
    }
    
    public static prefix func - (f: LaurentPolynomial<R>) -> LaurentPolynomial<R> {
        return f.mapCoeffs { -$0 }
    }
    
    public static func * (f: LaurentPolynomial<R>, g: LaurentPolynomial<R>) -> LaurentPolynomial<R> {
        let (d, D) = (f.lowerDegree + g.lowerDegree, f.upperDegree + g.upperDegree)
        return LaurentPolynomial(lowerDegree: d, upperDegree: D) { k in
            (max(f.lowerDegree, k - g.upperDegree) ... min(k - g.lowerDegree, f.upperDegree)).sum {
                f.coeff($0) * g.coeff(k - $0)
            }
        }
    }
    
    public static func * (r: R, f: LaurentPolynomial<R>) -> LaurentPolynomial<R> {
        return f.mapCoeffs { r * $0 }
    }
    
    public static func * (f: LaurentPolynomial<R>, r: R) -> LaurentPolynomial<R> {
        return f.mapCoeffs { $0 * r }
    }
    
    public var description: String {
        return Format.terms("+", (lowerDegree ... upperDegree).map{ i in (coeff(i), "x", i)}, skipZero: true)
    }
    
    public static var symbol: String {
        return "\(R.symbol)[x, x⁻¹]"
    }
    
    public var hashValue: Int {
        return leadCoeff.hashValue
    }
}
