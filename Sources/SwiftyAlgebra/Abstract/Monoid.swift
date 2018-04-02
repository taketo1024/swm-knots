import Foundation

public protocol Monoid: SetType {
    static func * (a: Self, b: Self) -> Self
    static var identity: Self { get }
    func pow(_ n: 𝐙) -> Self
}

public extension Monoid {
    public func pow(_ n: 𝐙) -> Self {
        assert(n >= 0)
        return (0 ..< n).reduce(.identity){ (res, _) in self * res }
    }
}

public protocol Submonoid: Monoid, Subset where Super: Monoid {}

public extension Submonoid {
    static var identity: Self {
        return Self(Super.identity)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self(a.asSuper * b.asSuper)
    }
}

public typealias ProductMonoid<X: Monoid, Y: Monoid> = ProductSet<X, Y>

extension ProductMonoid: Monoid where X: Monoid, Y: Monoid {
    public static var identity: ProductMonoid<X, Y> {
        return ProductMonoid(X.identity, Y.identity)
    }
    
    public static func * (a: ProductMonoid<X, Y>, b: ProductMonoid<X, Y>) -> ProductMonoid<X, Y> {
        return ProductMonoid(a._1 * b._1, a._2 * b._2)
    }
}
