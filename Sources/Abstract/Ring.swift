import Foundation

public protocol Ring: AdditiveGroup, Monoid, ExpressibleByIntegerLiteral {
    associatedtype IntegerLiteralType = IntegerNumber
    init(intValue: IntegerNumber)
    var isUnit: Bool { get }
    var unitInverse: Self { get }
    static func matrixElimination<n:_Int, m:_Int>(_ A: Matrix<Self, n, m>, mode: MatrixEliminationMode) -> BaseMatrixElimination<Self, n, m>
}

public extension Ring {
    // required init from `ExpressibleByIntegerLiteral`
    public init(integerLiteral value: IntegerNumber) {
        self.init(intValue: value)
    }
    
    // TODO must implement properly for each conforming struct.
    public var isUnit: Bool {
        return (self == Self.identity) || (self == -Self.identity)
    }

    var unitInverse: Self {
        if !isUnit {
            fatalError("\(self) is not a unit.")
        }
        return (self == Self.identity) ? self : -self
    }
    
    public static var zero: Self {
        return Self.init(intValue: 0)
    }
    
    public static var identity: Self {
        return Self.init(intValue: 1)
    }
    
    public static func **(a: Self, n: Int) -> Self {
        return (0 ..< n).reduce(Self.identity){ (res, _) in res * a }
    }
    
    // must override in subclass
    public static func matrixElimination<n:_Int, m:_Int>(_ A: Matrix<Self, n, m>, mode: MatrixEliminationMode) -> BaseMatrixElimination<Self, n, m> {
        return BaseMatrixElimination<Self, n, m>(A, mode: mode)
    }
}

public protocol Subring: Ring, Subgroup {
    associatedtype Super: Ring
    init(_ r: Super)
    var asSuper: Super { get }
    static func contains(_ r: Super) -> Bool
}

public extension Subring {
    static func + (a: Self, b: Self) -> Self {
        return Self.init(a.asSuper + b.asSuper)
    }
    
    prefix static func - (a: Self) -> Self {
        return Self.init(a.asSuper)
    }
}

public protocol Ideal: AdditiveGroup {
    associatedtype Super: Ring
    init(_ a: Super)
    var asSuper: Super { get }
    static func contains(_ a: Super) -> Bool
    static func * (r: Super, a: Self) -> Self
    static func * (m: Self, r: Super) -> Self
}

public extension Ideal {
    public static var zero: Self {
        return Self.init(Super.zero)
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self.init(a.asSuper + b.asSuper)
    }
    
    public static func == (a: Self, b: Self) -> Bool {
        return a.asSuper == b.asSuper
    }
    
    prefix static func - (a: Self) -> Self {
        return Self.init(a.asSuper)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self.init(a.asSuper * b.asSuper)
    }
    
    public static func * (r: Super, a: Self) -> Self {
        return Self.init(r * a.asSuper)
    }
    
    public static func * (a: Self, r: Super) -> Self {
        return Self.init(a.asSuper * r)
    }
    
    public var hashValue: Int {
        return asSuper.hashValue
    }
    
    public var description: String {
        return "[\(asSuper)]"
    }
}

public struct ProductRing<R1: Ring, R2: Ring>: Ring {
    public let _1: R1
    public let _2: R2
    
    public init(intValue a: Int) {
        self._1 = R1(intValue: a)
        self._2 = R2(intValue: a)
    }
    
    public init(_ g1: R1, _ g2: R2) {
        self._1 = g1
        self._2 = g2
    }
    
    public static var zero: ProductRing<R1, R2> {
        return ProductRing<R1, R2>(R1.zero, R2.zero)
    }
    
    public static var identity: ProductRing<R1, R2> {
        return ProductRing<R1, R2>(R1.identity, R2.identity)
    }
    
    public static var symbol: String {
        return "\(R1.symbol)×\(R2.symbol)"
    }
    
    public static func == (a: ProductRing<R1, R2>, b: ProductRing<R1, R2>) -> Bool {
        return (a._1 == b._1) && (a._2 == b._2)
    }
    
    public static func + (a: ProductRing<R1, R2>, b: ProductRing<R1, R2>) -> ProductRing<R1, R2> {
        return ProductRing<R1, R2>(a._1 + b._1, a._2 + b._2)
    }
    
    public static prefix func - (a: ProductRing<R1, R2>) -> ProductRing<R1, R2> {
        return ProductRing<R1, R2>(-a._1, -a._2)
    }
    
    public static func * (a: ProductRing<R1, R2>, b: ProductRing<R1, R2>) -> ProductRing<R1, R2> {
        return ProductRing<R1, R2>(a._1 * b._1, a._2 * b._2)
    }
    
    public var hashValue: Int {
        return (_1.hashValue &* 31) &+ _2.hashValue
    }
    
    public var description: String {
        return "(\(_1), \(_2))"
    }
}

public struct QuotientRing<R: Ring, I: Ideal>: Ring where R == I.Super {
    internal let r: R
    
    public init(intValue n: Int) {
        self.init(R(intValue: n))
    }
    
    public init(_ r: R) {
        self.r = r
    }
    
    public var representative: R {
        return r
    }
    
    public static var zero: QuotientRing<R, I> {
        return QuotientRing<R, I>(R.zero)
    }
    
    public static var identity: QuotientRing<R, I> {
        return QuotientRing<R, I>(R.identity)
    }
    
    public static func == (a: QuotientRing<R, I>, b: QuotientRing<R, I>) -> Bool {
        return I.contains( a.r - b.r )
    }
    
    public static func + (a: QuotientRing<R, I>, b: QuotientRing<R, I>) -> QuotientRing<R, I> {
        return QuotientRing<R, I>.init(a.r + b.r)
    }
    
    public static prefix func - (a: QuotientRing<R, I>) -> QuotientRing<R, I> {
        return QuotientRing<R, I>.init(-a.r)
    }
    
    public static func * (a: QuotientRing<R, I>, b: QuotientRing<R, I>) -> QuotientRing<R, I> {
        return QuotientRing<R, I>.init(a.r * b.r)
    }
    
    public static var symbol: String {
        return "\(R.symbol)/\(I.symbol)"
    }
    
    public var hashValue: Int {
        return r.hashValue
    }
    
    public var description: String {
        return "[\(r)]"
    }
}
