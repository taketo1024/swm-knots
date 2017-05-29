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

public struct QuotientGroup<G: Group, H: Subgroup>: Group where G == H.Super {
    public let representative: G
    private let subIdentity: H // necessary when H: DynamicSubgroup
    
    public init(_ g: G, _ h: H = H.identity) {
        self.representative = g
        self.subIdentity = h
    }
    
    public static var identity: QuotientGroup<G, H> {
        return QuotientGroup<G, H>(G.identity, H.identity)
    }
    
    public var inverse: QuotientGroup<G, H> {
        return QuotientGroup<G, H>(representative.inverse, H.identity)
    }
    
    public static var symbol: String {
        return "\(G.symbol)/\(H.symbol)"
    }
    
    public static func == (a: QuotientGroup<G, H>, b: QuotientGroup<G, H>) -> Bool {
        if let h = a.subIdentity as? DynamicSubgroup<G> {
            return h.typeContains( a.representative * b.representative.inverse )
        } else {
            return H.contains( a.representative * b.representative.inverse )
        }
    }
    
    public static func * (a: QuotientGroup<G, H>, b: QuotientGroup<G, H>) -> QuotientGroup<G, H> {
        return QuotientGroup<G, H>.init(a.representative * b.representative)
    }
}

/*
public struct DynamicSubgroup<G: Group>: Subgroup {
    public typealias Super = G
    public let element: G
    public let allElements: [G]
    
    public init(_ g: G) {
        fatalError("Must instantiate FiniteSubgroup<G> from FiniteSubgroup<G>.factory(allElements)")
    }
    
    public func factory(_ gs: [G]) -> ((G) -> FiniteSubgroup<G>) {
        return {(_ g: G) -> FiniteSubgroup<G> in
            return FiniteSubgroup<G>(g, gs)
        }
    }
    
    internal init(_ g: G, _ gs: [G])  {
        self.element = g
        self.allElements = Array(gs)
    }
    
    public var asSuper: G {
        return element
    }
    
    public static func contains(_ g: G) -> Bool {
        fatalError("The type FiniteSubgroup<G> cannot store the generating elements.")
    }
    
    public func typeContains(_ g: G) -> Bool {
        return allElements.contains(g)
    }
}
*/
