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
    
    public static func formsSubgroup<S: Sequence>(_ elements: S) -> Bool where S.Iterator.Element == Self {
        let list = Array(elements)
        let n = list.count
        
        // check ^-1 closed
        for g in list {
            if !elements.contains(g.inverse) {
                return false
            }
        }
        
        // check *-closed
        let combis = n.choose(2)
        for c in combis {
            let (g, h) = (list[c[0]], list[c[1]])
            if !elements.contains(g * h) {
                return false
            }
            if !elements.contains(h * g) {
                return false
            }
        }
        
        return true
    }
}

public extension Group where Self: FiniteType {
    public static func cyclicSubgroup(generator: Self) -> DynamicFiniteSubgroupFactory<Self> {
        var g = generator
        var set = Set([identity])
        while !set.contains(g) {
            set.insert(g)
            g = g * g
        }
        return DynamicFiniteSubgroupFactory(set)
    }
    
    public static var allCyclicSubgroups: [DynamicFiniteSubgroupFactory<Self>] {
        return allElements.map{ cyclicSubgroup(generator: $0) }.sorted{ $0.countElements < $1.countElements }
    }
    
    public static var allSubgroups: [DynamicFiniteSubgroupFactory<Self>] {
        let n = countElements
        if n == 1 {
            return [cyclicSubgroup(generator: identity)]
        }
        
        let cyclics = allCyclicSubgroups
        var unions: Set<Set<Self>> = Set()
        unions.insert(Set([identity]))
        
        for k in 2...cyclics.count {
            n.choose(k).forEach { c in
                let union: Set<Self> = c.map{ cyclics[$0] }.reduce(Set()){ $0.union($1.allElementsAsSuper) }
                
                // TODO improve algorithm
                if !unions.contains(union) && (n % union.count == 0) && formsSubgroup(union) {
                    unions.insert(union)
                }
            }
        }
        
        return unions
            .sorted{ $0.count < $1.count }
            .map{ DynamicFiniteSubgroupFactory($0) }
    }
}

public protocol Subgroup: Group, SubAlgebraicType {
    associatedtype Super: Group
}

public extension Subgroup {
    public var inverse: Self {
        return Self.init(self.asSuper.inverse)
    }
    
    static var identity: Self {
        return Self.init(Super.identity)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self.init(a.asSuper * b.asSuper)
    }
}

public struct ProductGroup<G1: Group, G2: Group>: Group, ProductAlgebraicType {
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
    
    public static func * (a: ProductGroup<G1, G2>, b: ProductGroup<G1, G2>) -> ProductGroup<G1, G2> {
        return ProductGroup<G1, G2>(a._1 * b._1, a._2 * b._2)
    }
}

public struct QuotientGroup<G: Group, H: Subgroup>: Group, QuotientAlgebraicType where G == H.Super {
    public typealias Sub = H
    internal let g: G
    
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

public protocol DynamicSubgroup: Subgroup, DynamicSubtype {
    associatedtype Super: Group
}

public extension DynamicSubgroup {
    public var inverse: Self {
        return Self.init(asSuper.inverse, factory: factory)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        if !typeMatches(a, b) {
            fatalError("unmatching type")
        }
        return Self.init(a.asSuper * b.asSuper, factory: a.factory ?? b.factory)
    }
}

public class DynamicSubgroupFactory<H: DynamicSubgroup>: DynamicSubtypeFactory<H> {
}

public struct DynamicFiniteSubgroup<G: Group>: DynamicSubgroup {
    public typealias Super = G
    
    private let g: G
    public var factory: DynamicTypeFactory<DynamicFiniteSubgroup<G>>?
    
    // root initializer
    public init(_ g: G, factory: DynamicTypeFactory<DynamicFiniteSubgroup<G>>?) {
        self.g = g
        self.factory = factory
    }
    
    public var asSuper: G {
        return g
    }
    
    public static func contains(_ g: G) -> Bool {
        print("[warn] DynamicFiniteSubgroup.contains will only return true for identity.")
        return g == G.identity
    }
    
    public var hashValue: Int {
        return g.hashValue
    }
    
    public static var symbol: String {
        return "DF<\(G.symbol)>"
    }
}

public final class DynamicFiniteSubgroupFactory<G: Group>: DynamicSubgroupFactory<DynamicFiniteSubgroup<G>> {
    public  let allElementsAsSuper: Set<G>
    private var _allElements: Set<DynamicFiniteSubgroup<G>>! = nil
    
    public init<S: Sequence>(_ allElements: S) where S.Iterator.Element == G {
        self.allElementsAsSuper = Set(allElements)
        self._allElements = nil
        super.init()
        
        self._allElements = Set(allElements.map{DynamicFiniteSubgroup<G>($0, factory: self)})
    }
    
    public var allElements: Set<DynamicFiniteSubgroup<G>> {
        return _allElements!
    }
    
    public var countElements: Int {
        return allElements.count
    }
    
    public override func contains(_ g: G) -> Bool {
        return allElementsAsSuper.contains(g)
    }
    
    public static func == (t1: DynamicFiniteSubgroupFactory<G>, t2: DynamicFiniteSubgroupFactory<G>) -> Bool {
        return t1.allElementsAsSuper == t2.allElementsAsSuper
    }
    
    public override var description: String {
        return "{\(Array(allElementsAsSuper).map{"\($0)"}.joined(separator: ", "))}"
    }
}

public struct DynamicQuotientGroup<G: Group, H: DynamicSubgroup>: Group, QuotientAlgebraicType where G == H.Super {
    public typealias Sub = H
    
    internal let g: G
    internal let subgroupFactory: DynamicSubgroupFactory<H>?
    
    public static func factory(subgroupFactory: DynamicSubgroupFactory<H>) -> ((_ g: G) -> DynamicQuotientGroup<G, H>) {
        return {(g: G) in DynamicQuotientGroup(g, subgroupFactory: subgroupFactory)}
    }
    
    public init(_ g: G) {
        self.init(g, subgroupFactory: nil)
    }
    
    internal init(_ g: G, subgroupFactory: DynamicSubgroupFactory<H>?) {
        self.g = g
        self.subgroupFactory = subgroupFactory
    }
    
    public static var identity: DynamicQuotientGroup<G, H> {
        return DynamicQuotientGroup<G, H>(G.identity)
    }
    
    public var representative: G {
        return g
    }
    
    public var inverse: DynamicQuotientGroup<G, H> {
        return DynamicQuotientGroup<G, H>(g.inverse, subgroupFactory: subgroupFactory)
    }
    
    private static func typeMatches(_ a: DynamicQuotientGroup, _ b: DynamicQuotientGroup<G, H>) -> Bool {
        return (a.subgroupFactory == b.subgroupFactory || a.subgroupFactory == nil || b.subgroupFactory == nil)
    }

    public static func == (a: DynamicQuotientGroup<G, H>, b: DynamicQuotientGroup<G, H>) -> Bool {
        if !typeMatches(a, b) {
            fatalError("cannot compare \(type(of: a)) with \(type(of: b))")
        }
        
        let g = a.g * b.g.inverse
        return g == G.identity || (a.subgroupFactory ?? b.subgroupFactory).flatMap{f in f.contains(g)} ?? false
    }
    
    public static func * (a: DynamicQuotientGroup<G, H>, b: DynamicQuotientGroup<G, H>) -> DynamicQuotientGroup<G, H> {
        return DynamicQuotientGroup<G, H>.init(a.g * b.g, subgroupFactory: a.subgroupFactory ?? b.subgroupFactory)
    }
    
    public var hashValue: Int {
        return (self == DynamicQuotientGroup<G, H>.identity) ? 0 : 1 // TODO think...
    }
}
