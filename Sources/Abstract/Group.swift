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

public class DynamicFiniteSubgroupType<G: Group>: Equatable, CustomStringConvertible {
    public typealias Super = G
    
    public  let allElementsAsSuper: Set<G>
    private var _allElements: Set<DynamicFiniteSubgroup<G>>!
    
    public init<S: Sequence>(_ allElements: S) where S.Iterator.Element == G {
        self.allElementsAsSuper = Set(allElements)
        self._allElements = Set(allElements.map{DynamicFiniteSubgroup<G>($0, self)})
    }
    
    public func contains(_ g: G) -> Bool {
        return allElementsAsSuper.contains(g)
    }
    
    public var allElements: Set<DynamicFiniteSubgroup<G>> {
        return _allElements!
    }
    
    public var countElements: Int {
        return allElements.count
    }
    
    public func asSub(_ g: G) -> DynamicFiniteSubgroup<G> {
        if !allElementsAsSuper.contains(g) {
            fatalError("\(g) not contained in this subgroup.")
        }
        return DynamicFiniteSubgroup<G>(g, self)
    }
    
    public static func == (t1: DynamicFiniteSubgroupType<G>, t2: DynamicFiniteSubgroupType<G>) -> Bool {
        return t1.allElementsAsSuper == t2.allElementsAsSuper
    }
    
    public var description: String {
        return "{\(Array(allElementsAsSuper).map{"\($0)"}.joined(separator: ", "))}"
    }
}

public struct DynamicFiniteSubgroup<G: Group>: Subgroup, CustomStringConvertible {
    public typealias Super = G
    
    private let g: G
    private let type: DynamicFiniteSubgroupType<G>? // empty when generated from static methods such as `identity`.
    
    // root initializer
    public init(_ g: G, _ type: DynamicFiniteSubgroupType<G>?) {
        self.g = g
        self.type = type
    }
    
    public init(_ g: G) {
        self.init(g, nil)
    }
    
    public var asSuper: G {
        return g
    }
    
    public static func contains(_ g: G) -> Bool {
        print("[warn] DynamicFiniteSubgroup.contains will only return true for identity.")
        return g == G.identity
    }
    
    private func typeMatches(with b: DynamicFiniteSubgroup<G>) -> Bool {
        return (self.type == b.type || self.type == nil || self.type == nil)
    }
    
    public static func == (a: DynamicFiniteSubgroup<G>, b: DynamicFiniteSubgroup<G>) -> Bool {
        return a.g == b.g && a.typeMatches(with: b)
    }
    
    public static func * (a: DynamicFiniteSubgroup<G>, b: DynamicFiniteSubgroup<G>) -> DynamicFiniteSubgroup<G> {
        if !a.typeMatches(with: b) {
            fatalError("unmatching type")
        }
        return DynamicFiniteSubgroup(a.asSuper * b.asSuper, a.type ?? b.type)
    }
    
    public static func formsSubgroup<S: Sequence>(_ elements: S) -> Bool where S.Iterator.Element == G {
        let list = Array(elements)
        let n = list.count
        
        // check ^-1 closed
        for g in list {
            if !elements.contains(g.inverse) {
                return false
            }
        }
        
        // check *-closed
        let combis = combi(n, 2)
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
    
    public var hashValue: Int {
        return asSuper.hashValue
    }
    
    public var description: String {
        return "\(g)"
    }
}

public extension Group where Self: FiniteType {
    public static func cyclicSubgroup(generator: Self) -> DynamicFiniteSubgroupType<Self> {
        var g = generator
        var set = Set([identity])
        while !set.contains(g) {
            set.insert(g)
            g = g * g
        }
        return DynamicFiniteSubgroupType(set)
    }
    
    public static var allCyclicSubgroups: [DynamicFiniteSubgroupType<Self>] {
        return allElements.map{ cyclicSubgroup(generator: $0) }.sorted{ $0.countElements < $1.countElements }
    }
    
    public static var allSubgroups: [DynamicFiniteSubgroupType<Self>] {
        let n = count
        if n == 1 {
            return [cyclicSubgroup(generator: identity)]
        }
        
        let cyclics = allCyclicSubgroups
        var unions: Set<Set<Self>> = Set()
        unions.insert(Set([identity]))
        
        for k in 2...cyclics.count {
            combi(n, k).forEach { c in
                let union: Set<Self> = c.map{ cyclics[$0] }.reduce(Set()){ $0.union($1.allElementsAsSuper) }
                
                // TODO improve algorithm
                if !unions.contains(union) && (n % union.count == 0) && DynamicFiniteSubgroup<Self>.formsSubgroup(union) {
                    unions.insert(union)
                }
            }
        }
        
        return unions
            .sorted{ $0.count < $1.count }
            .map{ DynamicFiniteSubgroupType($0) }
    }
}
