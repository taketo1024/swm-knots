import Foundation

public protocol Ring: AdditiveGroup, Monoid, ExpressibleByIntegerLiteral {
    associatedtype IntegerLiteralType = IntegerNumber
    init(intValue: IntegerNumber)
    var isUnit: Bool { get }
    var unitInverse: Self? { get }
    static func matrixElimination<n:_Int, m:_Int>(_ A: Matrix<Self, n, m>, mode: MatrixEliminationMode) -> BaseMatrixElimination<Self, n, m>
}

public extension Ring {
    // required init from `ExpressibleByIntegerLiteral`
    public init(integerLiteral value: IntegerNumber) {
        self.init(intValue: value)
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

public protocol Subring: Ring, Submonoid {
    associatedtype Super: Ring
}

public extension Subring {
    static func + (a: Self, b: Self) -> Self {
        return Self.init(a.asSuper + b.asSuper)
    }
    
    prefix static func - (a: Self) -> Self {
        return Self.init(a.asSuper)
    }
}

public protocol Ideal: AdditiveGroup, SubsetType {
    associatedtype Super: Ring
    static func * (r: Super, a: Self) -> Self
    static func * (m: Self, r: Super) -> Self
    
    static func reduced(_ a: Super) -> Super
    static func isUnitInQuotient(_ r: Super) -> Bool
    static func inverseInQuotient(_ r: Super) -> Super?
}

public extension Ideal {
    public static var zero: Self {
        return Self.init(Super.zero)
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self.init(a.asSuper + b.asSuper)
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
}

public protocol ProductRingType: Ring, ProductMonoidType {
    associatedtype Left: Ring
    associatedtype Right: Ring
}

public extension ProductRingType {
    public init(intValue a: Int) {
        self.init(Left(intValue: a), Right(intValue: a))
    }
    
    public var isUnit: Bool {
        return _1.isUnit && _2.isUnit
    }
    
    public var unitInverse: Self? {
        return isUnit ? Self.init(_1.unitInverse!, _2.unitInverse!) : nil
    }
    
    public static var zero: Self {
        return Self(Left.zero, Right.zero)
    }
    
    public static var identity: Self {
        return Self(Left.identity, Right.identity)
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self(a._1 + b._1, a._2 + b._2)
    }
    
    public static prefix func - (a: Self) -> Self {
        return Self(-a._1, -a._2)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self(a._1 * b._1, a._2 * b._2)
    }
}

public struct ProductRing<R1: Ring, R2: Ring>: ProductRingType {
    public typealias Left = R1
    public typealias Right = R2
    
    public let _1: R1
    public let _2: R2
    
    public init(_ r1: R1, _ r2: R2) {
        self._1 = r1
        self._2 = r2
    }
}

public protocol QuotientRingType: Ring, QuotientSetType {
    associatedtype Sub: Ideal
}

public extension QuotientRingType {
    public init(intValue n: Int) {
        self.init(Base(intValue: n))
    }
    
    public var isUnit: Bool {
        return Sub.isUnitInQuotient(representative)
    }
    
    public var unitInverse: Self? {
        return Sub.inverseInQuotient(representative).map{ Self.init($0) }
    }
    
    public static func isEquivalent(_ a: Base, _ b: Base) -> Bool {
        return Sub.contains( a - b )
    }
    
    public static var zero: Self {
        return Self.init(Base.zero)
    }
    
    public static var identity: Self {
        return Self.init(Base.identity)
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self.init(a.representative + b.representative)
    }
    
    public static prefix func - (a: Self) -> Self {
        return Self.init(-a.representative)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self.init(a.representative * b.representative)
    }
    
    public var hashValue: Int {
        return representative.hashValue
    }
}

public struct QuotientRing<R: Ring, I: Ideal>: QuotientRingType where R == I.Super {
    public typealias Sub = I
    
    internal let r: R
    
    public init(_ r: R) {
        self.r = I.reduced(r)
    }
    
    public var representative: R {
        return r
    }
}

public protocol QuotientFieldType: Field, QuotientRingType { }

public extension QuotientFieldType {
    public var isUnit: Bool {
        return Sub.isUnitInQuotient(representative)
    }
    
    public var unitInverse: Self? {
        return Sub.inverseInQuotient(representative).map{ Self.init($0) }
    }
    
    public var inverse: Self {
        return unitInverse!
    }
}

// TODO merge with QuotientRing after conditional conformance is supported.
public struct QuotientField<R: Ring, I: Ideal>: QuotientFieldType where R == I.Super {
    public typealias Sub = I
    
    internal let r: R
    
    public init(_ r: R) {
        self.r = I.reduced(r)
    }
    
    public var representative: R {
        return r
    }
}
