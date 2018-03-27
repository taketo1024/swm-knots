import Foundation

public protocol AdditiveGroup: SetType {
    static func + (a: Self, b: Self) -> Self
    prefix static func - (x: Self) -> Self
    static var zero: Self { get }
}

public extension AdditiveGroup {
    public static func -(a: Self, b: Self) -> Self {
        return (a + (-b))
    }
}

public protocol AdditiveSubgroup: AdditiveGroup, SubsetType where Super: AdditiveGroup {}

public extension AdditiveSubgroup {
    public static var zero: Self {
        return Self(Super.zero)
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self(a.asSuper + b.asSuper)
    }
    
    prefix static func - (a: Self) -> Self {
        return Self(-a.asSuper)
    }
}

public protocol AdditiveProductGroup: AdditiveGroup, ProductSetType where Left: AdditiveGroup, Right: AdditiveGroup {}

public extension AdditiveProductGroup {
    public static var zero: Self {
        return Self(Left.zero, Right.zero)
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self(a._1 + b._1, a._2 + b._2)
    }
    
    public static prefix func - (a: Self) -> Self {
        return Self(-a._1, -a._2)
    }
}

public protocol AdditiveQuotientGroup: AdditiveGroup, QuotientSetType {
    associatedtype Sub: AdditiveSubgroup
}

public extension AdditiveQuotientGroup where Base == Sub.Super {
    public static func isEquivalent(_ a: Base, _ b: Base) -> Bool {
        return Sub.contains( a - b )
    }
    
    public static var zero: Self {
        return Self(Base.zero)
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self(a.representative + b.representative)
    }
    
    public static prefix func - (a: Self) -> Self {
        return Self(-a.representative)
    }
    
    public static var symbol: String {
        return "\(Base.symbol)/\(Sub.symbol)"
    }
}

public protocol _AdditiveGroupHom: Map, AdditiveGroup where Domain: AdditiveGroup, Codomain: AdditiveGroup {}

public extension _AdditiveGroupHom {
    static var zero: Self {
        return Self { _ in .zero }
    }
    
    public static func + (f: Self, g: Self) -> Self {
        return Self { x in f.applied(to: x) + g.applied(to: x) }
    }
    
    prefix static func - (f: Self) -> Self {
        return Self { x in -f.applied(to: x) }
    }
}

public struct AdditiveGroupHom<X: AdditiveGroup, Y: AdditiveGroup>: _AdditiveGroupHom {
    public typealias Domain = X
    public typealias Codomain = Y
    
    private let f: (X) -> Y
    public init(_ f: @escaping (X) -> Y) {
        self.f = f
    }
    
    public func applied(to x: X) -> Y {
        return f(x)
    }
    
    public func composed<W>(with f: AdditiveGroupHom<W, X>) -> AdditiveGroupHom<W, Y> {
        return AdditiveGroupHom<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<Z>(g: AdditiveGroupHom<Y, Z>, f: AdditiveGroupHom<X, Y>) -> AdditiveGroupHom<X, Z> {
        return g.composed(with: f)
    }
}
