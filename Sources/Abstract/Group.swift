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
    
    public static func quotient<H: DynamicSubgroup>(by subgroupFactory: DynamicSubgroupFactory<H>) -> DynamicQuotientGroupFactory<Self, H> {
        return DynamicQuotientGroupFactory<Self, H>(subtypeFactory: subgroupFactory)
    }
}

public extension Group where Self: FiniteSetType {
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

public protocol Subgroup: Submonoid, SubsetType {
    associatedtype Super: Group
}

public extension Subgroup {
    public var inverse: Self {
        return Self.init(self.asSuper.inverse)
    }
}

public protocol ProductGroupType: Group, ProductMonoidType {
    associatedtype Left: Group
    associatedtype Right: Group
}

public extension ProductGroupType {
    public var inverse: Self {
        return Self.init(_1.inverse, _2.inverse)
    }
}

// concrete class
public struct ProductGroup<G1: Group, G2: Group>: ProductGroupType {
    public typealias Left = G1
    public typealias Right = G2
    
    public let _1: G1
    public let _2: G2
    
    public init(_ g1: G1, _ g2: G2) {
        self._1 = g1
        self._2 = g2
    }
}

public protocol QuotientGroupType: Group, QuotientSetType {
    associatedtype Sub: Subgroup
}

public extension QuotientGroupType {
    
    public static var identity: Self {
        return Self(Base.identity)
    }
    
    public var inverse: Self {
        return Self(representative.inverse)
    }
    
    public static func isEquivalent(_ a: Base, _ b: Base) -> Bool {
        return Sub.contains(a * b.inverse)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self.init(a.representative * b.representative)
    }
    
    public var hashValue: Int {
        return 0 // Sub.contains(representative) ? 0 : 1 // better override in subclass
    }
}

// concrete class
public struct QuotientGroup<G: Group, H: Subgroup>: QuotientGroupType where G == H.Super {
    public typealias Base = G
    public typealias Sub = H
    
    internal let g: G
    
    public init(_ g: G) {
        self.g = g
    }
    
    public var representative: G {
        return g
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

public final class DynamicQuotientGroupFactory<G: Group, H: DynamicSubgroup>: DynamicQuotientTypeFactory<DynamicQuotientGroup<G, H>> where G == H.Super {
    public override func isEquivalent(_ a: Base, _ b: Base) -> Bool {
        return subtypeFactory.contains( a * b.inverse )
    }
}

public struct DynamicQuotientGroup<G: Group, H: DynamicSubgroup>: Group, DynamicQuotientType where G == H.Super {
    public typealias Sub = H
    
    internal let g: G
    public let factory: DynamicTypeFactory<DynamicQuotientGroup<G, H>>?
    
    public init(_ g: G, factory: DynamicTypeFactory<DynamicQuotientGroup<G, H>>?) {
        self.g = g
        self.factory = factory
    }
    
    public var representative: G {
        return g
    }
    
    public var inverse: DynamicQuotientGroup<G, H> {
        return DynamicQuotientGroup<G, H>(g.inverse, factory: factory)
    }
    
    public static var identity: DynamicQuotientGroup<G, H> {
        return DynamicQuotientGroup<G, H>(G.identity)
    }
    
    public static func == (a: DynamicQuotientGroup<G, H>, b: DynamicQuotientGroup<G, H>) -> Bool {
        if !typeMatches(a, b) {
            fatalError("cannot compare \(type(of: a)) with \(type(of: b))")
        }
        
        return (a.g == b.g) || (a.quotientFactory ?? b.quotientFactory).flatMap{f in f.isEquivalent(a.g, b.g)} ?? false
    }
    
    public static func * (a: DynamicQuotientGroup<G, H>, b: DynamicQuotientGroup<G, H>) -> DynamicQuotientGroup<G, H> {
        return DynamicQuotientGroup<G, H>.init(a.g * b.g, factory: a.factory ?? b.factory)
    }
    
    public var hashValue: Int {
        return (self == DynamicQuotientGroup<G, H>.identity) ? 0 : 1 // TODO think...
    }
    
    public static func isEquivalent(_ a: G, _ b: G) -> Bool {
        fatalError("DynamicQuotientType cannot statically determine `isEquivalent`")
    }
}
