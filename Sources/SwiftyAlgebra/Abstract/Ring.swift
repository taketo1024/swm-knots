import Foundation

public protocol Ring: AdditiveGroup, Monoid {
    init(from: 𝐙)
    var inverse: Self? { get }
    var isInvertible: Bool { get }
    var normalizeUnit: Self { get }
    static var isField: Bool { get }
}

public extension Ring {
    public var isInvertible: Bool {
        return (inverse != nil)
    }
    
    public var normalizeUnit: Self {
        return .identity
    }
    
    public func pow(_ n: Int) -> Self {
        if n >= 0 {
            return (0 ..< n).reduce(.identity){ (res, _) in self * res }
        } else {
            return (0 ..< -n).reduce(.identity){ (res, _) in inverse! * res }
        }
    }
    
    public static var zero: Self {
        return Self(from: 0)
    }
    
    public static var identity: Self {
        return Self(from: 1)
    }
    
    public static var isField: Bool {
        return false
    }
}

public protocol Subring: Ring, AdditiveSubgroup, Submonoid where Super: Ring {}

public extension Subring {
    public init(from n: 𝐙) {
        self.init( Super.init(from: n) )
    }

    public var inverse: Self? {
        return asSuper.inverse.flatMap{ Self.init($0) }
    }
    
    public static var zero: Self {
        return Self.init(from: 0)
    }
    
    public static var identity: Self {
        return Self.init(from: 1)
    }
}

public protocol Ideal: AdditiveSubgroup where Super: Ring {
    static func * (r: Super, a: Self) -> Self
    static func * (m: Self, r: Super) -> Self
    
    static func reduced(_ a: Super) -> Super
    static func inverseInQuotient(_ r: Super) -> Super?
}

public extension Ideal {
    public static func * (a: Self, b: Self) -> Self {
        return Self(a.asSuper * b.asSuper)
    }
    
    public static func * (r: Super, a: Self) -> Self {
        return Self(r * a.asSuper)
    }
    
    public static func * (a: Self, r: Super) -> Self {
        return Self(a.asSuper * r)
    }
}

public typealias ProductRing<X: Ring, Y: Ring> = AdditiveProductGroup<X, Y>

extension ProductRing: Ring where Left: Ring, Right: Ring {
    public init(from a: 𝐙) {
        self.init(Left(from: a), Right(from: a))
    }
    
    public var inverse: ProductRing<Left, Right>? {
        return left.inverse.flatMap{ r1 in right.inverse.flatMap{ r2 in ProductRing(r1, r2) }  }
    }
    
    public static var zero: ProductRing<Left, Right> {
        return ProductRing(.zero, .zero)
    }
    
    public static var identity: ProductRing<Left, Right> {
        return ProductRing(.identity, .identity)
    }
    
    public static func * (a: ProductRing<Left, Right>, b: ProductRing<Left, Right>) -> ProductRing<Left, Right> {
        return ProductRing(a.left * b.left, a.right * b.right)
    }
}

public typealias QuotientRing<R, I: Ideal> = AdditiveQuotientGroup<R, I> where R == I.Super

// MEMO cannot directly write `QuotientRing: Ring` for some reason. (Swift 4.1)

extension QuotientRing: Monoid, Ring where Sub: Ideal, Base == Sub.Super {
    public init(from n: 𝐙) {
        self.init(Base(from: n))
    }
    
    public var inverse: QuotientRing<Base, Sub>? {
        return Sub.inverseInQuotient(representative).map{ QuotientRing($0) }
    }
    
    public static func * (a: QuotientRing<Base, Sub>, b: QuotientRing<Base, Sub>) -> QuotientRing<Base, Sub> {
        return QuotientRing(a.representative * b.representative)
    }
}

extension QuotientRing: ExpressibleByIntegerLiteral where Base: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Base.IntegerLiteralType
    public init(integerLiteral value: Base.IntegerLiteralType) {
        self.init(Base(integerLiteral: value))
    }
}

public protocol MaximalIdeal: Ideal {}

extension QuotientRing: EuclideanRing where Sub: MaximalIdeal {
    public var degree: Int {
        return self == .zero ? 0 : 1
    }
    
    public static func eucDiv(_ a: QuotientRing<Base, Sub>, _ b: QuotientRing<Base, Sub>) -> (q: QuotientRing<Base, Sub>, r: QuotientRing<Base, Sub>) {
        return (a * b.inverse!, .zero)
    }
}

extension QuotientRing: Field where Sub: MaximalIdeal {}

public protocol RingHomType: AdditiveGroupHomType where Domain: Ring, Codomain: Ring {}

public typealias RingHom<R1: Ring, R2: Ring> = AdditiveGroupHom<R1, R2>
extension RingHom: RingHomType where Domain: Ring, Codomain: Ring {}
