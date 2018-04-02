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

public typealias QuotientModule<M, N: Submodule> = AdditiveQuotientGroup<M, N> where M == N.Super

extension QuotientModule: Module where Sub: Submodule {
    public typealias CoeffRing = Base.CoeffRing
    
    public static func * (r: CoeffRing, a: QuotientModule<Base, Sub>) -> QuotientModule<Base, Sub> {
        return QuotientModule(r * a.representative)
    }
    
    public static func * (a: QuotientModule<Base, Sub>, r: CoeffRing) -> QuotientModule<Base, Sub> {
        return QuotientModule(a.representative * r)
    }
}
