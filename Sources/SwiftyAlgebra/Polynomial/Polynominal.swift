import Foundation

public struct Polynomial<R: Ring>: Ring, Module {
    public typealias CoeffRing = R
    internal let coeffs: [R]
    
    public init(from n: 𝐙) {
        let a = R(from: n)
        self.init(coeffs: [a])
    }
    
    public init(coeffs: [R]) {
        assert(coeffs.count > 0)
        if coeffs.last! == .zero {
            let dropped = coeffs.dropLast{ $0 == R.zero }.toArray()
            self.coeffs = dropped.isEmpty ? [.zero] : dropped
        } else {
            self.coeffs = coeffs
        }
    }
    
    public init(_ coeffs: R...) {
        self.init(coeffs: coeffs)
    }
    
    public init(degree: Int, gen: ((Int) -> R)) {
        let coeffs = (0 ... degree).map(gen)
        self.init(coeffs: coeffs)
    }
    
    public var normalizeUnit: Polynomial<R> {
        return Polynomial(leadCoeff.inverse!)
    }
    
    public var degree: Int {
        return coeffs.count - 1
    }
    
    public var inverse: Polynomial<R>? {
        return (degree == 0 && self != .zero) ? Polynomial<R>(coeff(0).inverse!) : nil
    }
    
    public var leadCoeff: R {
        return coeffs[degree]
    }
    
    public func coeff(_ i: Int) -> R {
        return i < coeffs.count ? coeffs[i] : .zero
    }
    
    // Horner's method
    // see: https://en.wikipedia.org/wiki/Horner%27s_method
    public func evaluate(_ x: R) -> R {
        return (0 ..< degree).reversed().reduce(leadCoeff) { (res, i) in
            coeff(i) + x * res
        }
    }
    
    // MEMO: more generally, this could be done with any superring of K.
    public func evaluate<n>(_ x: SquareMatrix<n, R>) -> SquareMatrix<n, R> {
        typealias M = SquareMatrix<n, R>
        return (0 ..< degree).reversed().reduce(leadCoeff * M.identity) { (res, i) -> M in
            M(scalar: coeff(i)) + x * res // <- the compiler complains that this is too complex...
        }
    }
    
    public func mapCoeffs(_ f: ((R) -> R)) -> Polynomial<R> {
        return Polynomial<R>(coeffs: coeffs.map(f))
    }
    
    public var derivative: Polynomial<R> {
        return Polynomial<R>.init(degree: degree - 1) {
            R(from: $0 + 1) * coeff($0 + 1)
        }
    }
    
    public static var indeterminate: Polynomial<R> {
        return Polynomial<R>(.zero, .identity)
    }
    
    public static func == (f: Polynomial<R>, g: Polynomial<R>) -> Bool {
        return (f.degree == g.degree) &&
            (0 ... f.degree).reduce(true) { $0 && (f.coeff($1) == g.coeff($1)) }
    }
    
    public static func + (f: Polynomial<R>, g: Polynomial<R>) -> Polynomial<R> {
        return Polynomial<R>(degree: max(f.degree, g.degree)) { f.coeff($0) + g.coeff($0) }
    }
    
    public static prefix func - (f: Polynomial<R>) -> Polynomial<R> {
        return f.mapCoeffs { -$0 }
    }
    
    public static func * (f: Polynomial<R>, g: Polynomial<R>) -> Polynomial<R> {
        return Polynomial<R>(degree: f.degree + g.degree) {
            (k: Int) in
            (max(0, k - g.degree) ... min(k, f.degree)).reduce(.zero) {
                (res:R, i:Int) in res + f.coeff(i) * g.coeff(k - i)
            }
        }
    }
    
    public static func * (r: R, f: Polynomial<R>) -> Polynomial<R> {
        return f.mapCoeffs { r * $0 }
    }
    
    public static func * (f: Polynomial<R>, r: R) -> Polynomial<R> {
        return f.mapCoeffs { $0 * r }
    }
    
    public var description: String {
        return Format.terms("+", coeffs.enumerated().reversed().map{(n, a) in (a, "x", n)}, skipZero: true)
    }
    
    public static var symbol: String {
        return "\(R.symbol)[x]"
    }
    
    public var hashValue: Int {
        return leadCoeff.hashValue
    }
}

extension Polynomial: EuclideanRing where R: Field {
    
    public func toMonic() -> Polynomial<R> {
        let a = leadCoeff
        return self.mapCoeffs{ $0 / a }
    }
    
    public static func eucDiv<K: Field>(_ f: Polynomial<K>, _ g: Polynomial<K>) -> (q: Polynomial<K>, r: Polynomial<K>) {
        if g == .zero {
            fatalError("divide by 0")
        }
        
        func eucDivMonomial(_ f: Polynomial<K>, _ g: Polynomial<K>) -> (q: Polynomial<K>, r: Polynomial<K>) {
            let n = f.degree - g.degree
            
            if n < 0 {
                return (.zero, f)
            } else {
                let x = Polynomial<K>.indeterminate
                let a = f.leadCoeff / g.leadCoeff
                let q = a * x.pow(n)
                let r = f - q * g
                return (q, r)
            }
        }
        
        return (0 ... max(0, f.degree - g.degree))
            .reversed()
            .reduce( (.zero, f) ) { (result: (Polynomial<K>, Polynomial<K>), degree: Int) in
                let (q, r) = result
                let m = eucDivMonomial(r, g)
                return (q + m.q, m.r)
        }
    }
}
