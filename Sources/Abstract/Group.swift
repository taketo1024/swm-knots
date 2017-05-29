import Foundation

public protocol Group: Monoid {
    var inverse: Self { get }
}

public func ** <G: Group>(a: G, b: Int) -> G {
    switch b {
    case let n where n > 0:
        return a * (a ** (n - 1))
    case let n where n < 0:
        return a.inverse * (a ** (n + 1))
    default:
        return G.identity
    }
}

public protocol Subgroup: Group {
    associatedtype Super: Group
    init(_ g: Super)
    var asSuper: Super { get }
    static func contains(_ g: Super) -> Bool
}

public extension Subgroup {
    public var inverse: Self {
        return Self.init(self.asSuper.inverse)
    }
    
    static var identity: Self {
        return Self.init(Super.identity)
    }
    
    public static var symbol: String {
        return "\(Self.self)"
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self.init(a.asSuper * b.asSuper)
    }
}

public struct ProductGroup<G1: Group, G2: Group>: Group {
    public let _1: G1
    public let _2: G2
    
    public init(_ g1: G1, _ g2: G2) {
        self._1 = g1
        self._2 = g2
    }
    
    public var inverse: ProductGroup<G1, G2> {
        return ProductGroup<G1, G2>(_1.inverse, _2.inverse)
    }
    
    public static var identity: ProductGroup<G1, G2> {
        return ProductGroup<G1, G2>(G1.identity, G2.identity)
    }
    
    public static var symbol: String {
        return "\(G1.symbol)×\(G2.symbol)"
    }
    
    public static func == (a: ProductGroup<G1, G2>, b: ProductGroup<G1, G2>) -> Bool {
        return (a._1 == b._1) && (a._2 == b._2)
    }
    
    public static func * (a: ProductGroup<G1, G2>, b: ProductGroup<G1, G2>) -> ProductGroup<G1, G2> {
        return ProductGroup<G1, G2>(a._1 * b._1, a._2 * b._2)
    }
}


public struct QuotientGroup<G: Group, H: Subgroup>: Group where G == H.Super {
    public let representative: G
    
    public init(_ g: G) {
        self.representative = g
    }
    
    public static var identity: QuotientGroup<G, H> {
        return QuotientGroup<G, H>(G.identity)
    }
    
    public var inverse: QuotientGroup<G, H> {
        return QuotientGroup<G, H>(representative.inverse)
    }
    
    public static var symbol: String {
        return "\(G.symbol)/\(H.symbol)"
    }
    
    public static func == (a: QuotientGroup<G, H>, b: QuotientGroup<G, H>) -> Bool {
        return H.contains( a.representative * b.representative.inverse )
    }
    
    public static func * (a: QuotientGroup<G, H>, b: QuotientGroup<G, H>) -> QuotientGroup<G, H> {
        return QuotientGroup<G, H>.init(a.representative * b.representative)
    }
}
