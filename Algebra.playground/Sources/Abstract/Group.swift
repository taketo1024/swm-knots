import Foundation

public protocol Group: Monoid {
    var inverse: Self {get}
}

public func ^<G: Group>(lhs: G, rhs: Int) -> G {
    return (rhs == 0) ? G.identity : lhs * (lhs ^ (rhs - 1))
}

public extension Group {
    static func testAssociativity(a: Self, _ b: Self, _ c: Self) -> Bool {
        return (a * b) * c == a * (b * c)
    }
    
    static func testIdentity(a: Self) -> Bool {
        return (a * Self.identity == a) && (Self.identity * a == a)
    }
    
    static func testInverse(a: Self) -> Bool {
        return (a * a.inverse == Self.identity) && (a.inverse * a == Self.identity)
    }
}