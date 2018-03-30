import Foundation

public protocol Module: AdditiveGroup {
    associatedtype CoeffRing: Ring
    static func * (r: CoeffRing, m: Self) -> Self
    static func * (m: Self, r: CoeffRing) -> Self
}

public protocol Submodule: Module, AdditiveSubgroup where Super: Module {}

public extension Submodule where CoeffRing == Super.CoeffRing {
    static func * (r: CoeffRing, a: Self) -> Self {
        return Self(r * a.asSuper)
    }
    
    static func * (a: Self, r: CoeffRing) -> Self {
        return Self(a.asSuper * r)
    }
}

public protocol _ProductModule: Module, AdditiveProductGroup where Left: Module, Right: Module {}

public extension _ProductModule where Left.CoeffRing == CoeffRing, Right.CoeffRing == CoeffRing {
    static func * (r: CoeffRing, a: Self) -> Self {
        return Self(r * a._1, r * a._2)
    }
    
    static func * (a: Self, r: CoeffRing) -> Self {
        return Self(a._1 * r, a._2 * r)
    }
    
    public static var symbol: String {
        return "\(Left.symbol)⊕\(Right.symbol)"
    }
}

public struct ProductModule<M1: Module, M2: Module>: _ProductModule where M1.CoeffRing == M2.CoeffRing {
    public typealias Left = M1
    public typealias Right = M2
    public typealias CoeffRing = M1.CoeffRing
    
    public let _1: M1
    public let _2: M2
    
    public init(_ m1: M1, _ m2: M2) {
        self._1 = m1
        self._2 = m2
    }
}

public protocol _QuotientModule: Module, AdditiveQuotientGroup where Sub: Submodule {}

public extension _QuotientModule where Base == Sub.Super, CoeffRing == Sub.CoeffRing, CoeffRing == Sub.Super.CoeffRing {
    public static func isEquivalent(_ a: Base, _ b: Base) -> Bool {
        return Sub.contains( a - b )
    }
    
    static func * (r: CoeffRing, a: Self) -> Self {
        return Self(r * a.representative)
    }
    
    static func * (a: Self, r: CoeffRing) -> Self {
        return Self(a.representative * r)
    }
    
    public var hashValue: Int {
        return representative.hashValue // must assure `representative` is unique.
    }
}

public struct QuotientModule<M, N>: _QuotientModule where N: Submodule, M == N.Super, M.CoeffRing == N.CoeffRing {
    public typealias CoeffRing = M.CoeffRing
    public typealias Sub = N
    
    internal let m: M
    
    public init(_ m: M) {
        self.m = m // TODO reduce
    }
    
    public var representative: M {
        return m
    }
}

public protocol _ModuleHom: _AdditiveGroupHom, Module where Domain: Module, Codomain : Module, CoeffRing == Domain.CoeffRing, CoeffRing == Codomain.CoeffRing {}

public extension _ModuleHom {
    public static func *(r: CoeffRing, f: Self) -> Self {
        return Self { x in r * f.applied(to: x) }
    }
    
    public static func *(f: Self, r: CoeffRing) -> Self {
        return Self { x in f.applied(to: x) * r }
    }
    
    public static var symbol: String {
        return "Hom_\(CoeffRing.symbol)(\(Domain.symbol), \(Codomain.symbol))"
    }
}

public struct ModuleHom<X: Module, Y: Module>: _ModuleHom where X.CoeffRing == Y.CoeffRing {
    public typealias CoeffRing = X.CoeffRing
    
    public typealias Domain = X
    public typealias Codomain = Y
    
    private let f: (X) -> Y
    public init(_ f: @escaping (X) -> Y) {
        self.f = f
    }
    
    public func applied(to x: X) -> Y {
        return f(x)
    }
    
    public func composed<W>(with f: ModuleHom<W, X>) -> ModuleHom<W, Y> {
        return ModuleHom<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<Z>(g: ModuleHom<Y, Z>, f: ModuleHom<X, Y>) -> ModuleHom<X, Z> {
        return g.composed(with: f)
    }
}

