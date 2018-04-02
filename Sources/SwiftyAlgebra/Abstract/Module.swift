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

public typealias ProductModule<X: Module, Y: Module> = AdditiveProductGroup<X, Y>

extension ProductModule: Module where X: Module, Y: Module, X.CoeffRing == Y.CoeffRing {
    public typealias CoeffRing = X.CoeffRing
    
    public static func * (r: CoeffRing, a: ProductModule<X, Y>) -> ProductModule<X, Y> {
        return ProductModule(r * a._1, r * a._2)
    }
    
    public static func * (a: ProductModule<X, Y>, r: CoeffRing) -> ProductModule<X, Y> {
        return ProductModule(a._1 * r, a._2 * r)
    }
    
    public static var symbol: String {
        return "\(X.symbol)⊕\(Y.symbol)"
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
