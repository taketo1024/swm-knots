import Foundation

public protocol Group: Monoid {
    var inverse: Self { get }
}

public extension Group {
    public static func ** (a: Self, b: Int) -> Self {
        switch b {
        case let n where n > 0:
            return a * (a ** (n - 1))
        case let n where n < 0:
            return a.inverse * (a ** (n + 1))
        default:
            return Self.identity
        }
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
    
    public var hashValue: Int {
        return asSuper.hashValue
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
    
    public var hashValue: Int {
        return (_1.hashValue &* 31) &+ _2.hashValue
    }
}


public struct QuotientGroup<G: Group, H: Subgroup>: Group where G == H.Super {
    private let g: G
    
    public init(_ g: G) {
        self.g = g
    }
    
    public static var identity: QuotientGroup<G, H> {
        return QuotientGroup<G, H>(G.identity)
    }
    
    public var representative: G {
        return g
    }
    
    public var inverse: QuotientGroup<G, H> {
        return QuotientGroup<G, H>(g.inverse)
    }
    
    public static var symbol: String {
        return "\(G.symbol)/\(H.symbol)"
    }
    
    public static func == (a: QuotientGroup<G, H>, b: QuotientGroup<G, H>) -> Bool {
        return H.contains( a.g * b.g.inverse )
    }
    
    public static func * (a: QuotientGroup<G, H>, b: QuotientGroup<G, H>) -> QuotientGroup<G, H> {
        return QuotientGroup<G, H>.init(a.g * b.g)
    }
    
    public var hashValue: Int {
        return g.hashValue
    }
}
