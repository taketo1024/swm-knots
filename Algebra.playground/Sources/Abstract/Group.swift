import Foundation

public protocol Group: Monoid {
    var inverse: Self {get}
}

public func ^<G: Group>(lhs: G, rhs: Int) -> G {
    switch rhs {
    case let n where n > 0:
        return lhs * (lhs ^ (n - 1))
    case let n where n < 0:
        return lhs.inverse * (lhs ^ (n + 1))
    default:
        return G.identity
    }
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