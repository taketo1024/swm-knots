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

extension ProductRing: Ring where X: Ring, Y: Ring {
    public init(from a: 𝐙) {
        self.init(X(from: a), Y(from: a))
    }
    
    public var inverse: ProductRing<X, Y>? {
        return _1.inverse.flatMap{ r1 in _2.inverse.flatMap{ r2 in ProductRing(r1, r2) }  }
    }
    
    public static var zero: ProductRing<X, Y> {
        return ProductRing(X.zero, Y.zero)
    }
    public static var identity: ProductRing<X, Y> {
        return ProductRing(X.identity, Y.identity)
    }
    
    public static func * (a: ProductRing<X, Y>, b: ProductRing<X, Y>) -> ProductRing<X, Y> {
        return ProductRing(a._1 * b._1, a._2 * b._2)
    }
}

public protocol _QuotientRing: Ring, AdditiveQuotientGroup where Sub: Ideal {}

public extension _QuotientRing where Base == Sub.Super {
    public init(from n: 𝐙) {
        self.init(Base(from: n))
    }
    
    public var inverse: Self? {
        return Sub.inverseInQuotient(representative).map{ Self($0) }
    }
    
    public static var zero: Self {
        return Self(.zero)
    }
    
    public static var identity: Self {
        return Self(.identity)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self(a.representative * b.representative)
    }
    
    public var hashValue: Int {
        return representative.hashValue // must assure `representative` is unique.
    }
}

public struct QuotientRing<R, I>: _QuotientRing where I: Ideal, R == I.Super {
    public typealias Sub = I
    
    internal let r: R
    
    public init(_ r: R) {
        self.r = I.reduced(r)
    }
    
    public var representative: R {
        return r
    }
}

public protocol MaximalIdeal: Ideal {}

// memo `QuotientRing: Field where I: MaximalIdeal` causes error...
extension QuotientRing: EuclideanRing where I: MaximalIdeal {
    public var degree: Int {
        return self == .zero ? 0 : 1
    }
    
    public static func eucDiv(_ a: QuotientRing<R, I>, _ b: QuotientRing<R, I>) -> (q: QuotientRing<R, I>, r: QuotientRing<R, I>) {
        return (a * b.inverse!, .zero)
    }
}

extension QuotientRing: Field where I: MaximalIdeal {}
