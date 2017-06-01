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
    
    public var description: String {
        return "(\(_1), \(_2))"
    }
}

public struct QuotientGroup<G: Group, H: Subgroup>: Group where G == H.Super {
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
    
    public var description: String {
        return "[\(g)]"
    }
}

// abstract class
public class DynamicSubgroupFactory<G: Group, H: DynamicSubgroup>: Equatable, CustomStringConvertible where G == H.Super {
    public func asSub(_ g: G) -> H {
        if !self.contains(g) {
            fatalError("\(H.self) does not contain element: \(g)")
        }
        return H.init(g, factory: self)
    }
    
    public func contains(_ g: G) -> Bool {
        fatalError("implement in subclass.")
    }
    
    public static func == (t1: DynamicSubgroupFactory<G, H>, t2: DynamicSubgroupFactory<G, H>) -> Bool {
        return type(of: t1) == type(of: t2)
    }
    
    public var description: String {
        return "\(type(of: self))"
    }
    
}

public protocol DynamicSubgroup: Subgroup {
    init(_ g: Super, factory: DynamicSubgroupFactory<Super, Self>?)
    var factory: DynamicSubgroupFactory<Super, Self>? { get }
}

internal extension DynamicSubgroup {
    func typeMatches(with b: Self) -> Bool {
        return (self.factory == b.factory || self.factory == nil || self.factory == nil)
    }
}

public final class DynamicFiniteSubgroupFactory<G: Group>: DynamicSubgroupFactory<G, DynamicFiniteSubgroup<G>> {
    public typealias Super = G
    
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

public struct DynamicFiniteSubgroup<G: Group>: DynamicSubgroup {
    public typealias Super = G
    
    private let g: G
    public var factory: DynamicSubgroupFactory<G, DynamicFiniteSubgroup<G>>?
    
    // root initializer
    public init(_ g: G, factory: DynamicSubgroupFactory<G, DynamicFiniteSubgroup<G>>?) {
        self.g = g
        self.factory = factory
    }
    
    public init(_ g: G) {
        self.init(g, factory: nil)
    }
    
    public var asSuper: G {
        return g
    }
    
    public static func contains(_ g: G) -> Bool {
        print("[warn] DynamicFiniteSubgroup.contains will only return true for identity.")
        return g == G.identity
    }
    
    public static func == (a: DynamicFiniteSubgroup<G>, b: DynamicFiniteSubgroup<G>) -> Bool {
        return a.g == b.g && a.typeMatches(with: b)
    }
    
    public static func * (a: DynamicFiniteSubgroup<G>, b: DynamicFiniteSubgroup<G>) -> DynamicFiniteSubgroup<G> {
        if !a.typeMatches(with: b) {
            fatalError("unmatching type")
        }
        return DynamicFiniteSubgroup(a.asSuper * b.asSuper, factory: a.factory ?? b.factory)
    }
    
    public var hashValue: Int {
        return asSuper.hashValue
    }
    
    public var description: String {
        return "\(asSuper)"
    }
}

public struct DynamicQuotientGroup<G: Group, H: DynamicSubgroup>: Group where G == H.Super {
    internal let g: G
    internal let subgroupFactory: DynamicSubgroupFactory<G, H>?
    
    public init(_ g: G) {
        self.init(g, subgroupFactory: nil)
    }
    
    public init(_ g: G, subgroupFactory: DynamicSubgroupFactory<G, H>?) {
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
    
    public static var symbol: String {
        return "\(G.symbol)/\(H.symbol)"
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
        return (g == G.identity) ? 0 : 1 // TODO think...
    }
    
    public var description: String {
        return "[\(g)]"
    }
}
