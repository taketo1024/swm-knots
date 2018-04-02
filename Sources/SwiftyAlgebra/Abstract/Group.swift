import Foundation

public protocol Group: Monoid {
    var inverse: Self { get }
}

public extension Group {
    public func pow(_ n: 𝐙) -> Self {
        if n >= 0 {
            return (0 ..< n).reduce(.identity){ (res, _) in self * res }
        } else {
            return (0 ..< -n).reduce(.identity){ (res, _) in inverse * res }
        }
    }
}

public protocol Subgroup: Submonoid where Super: Group {}

public extension Subgroup {
    public var inverse: Self {
        return Self(self.asSuper.inverse)
    }
}

public extension Group {
    public static func formsSubgroup<S: Sequence>(_ elements: S) -> Bool where S.Element == Self {
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

public extension Group where Self: FiniteSet {
    public static func cyclicSubgroup(generator: Self) -> FiniteSubgroupStructure<Self> {
        var g = generator
        var set = Set([identity])
        while !set.contains(g) {
            set.insert(g)
            g = g * g
        }
        return FiniteSubgroupStructure(allElements: set)
    }
    
    public static var allCyclicSubgroups: [FiniteSubgroupStructure<Self>] {
        return allElements.map{ cyclicSubgroup(generator: $0) }.sorted{ $0.countElements < $1.countElements }
    }
    
    public static var allSubgroups: [FiniteSubgroupStructure<Self>] {
        let n = countElements
        if n == 1 {
            return [cyclicSubgroup(generator: identity)]
        }
        
        let cyclics = allCyclicSubgroups
        var unions: Set<Set<Self>> = Set()
        unions.insert(Set([identity]))
        
        for k in 2...cyclics.count {
            n.choose(k).forEach { c in
                let union: Set<Self> = c.map{ cyclics[$0] }.reduce([]){ $0.union($1.allElements) }
                
                // TODO improve algorithm
                if !unions.contains(union) && (n % union.count == 0) && formsSubgroup(union) {
                    unions.insert(union)
                }
            }
        }
        
        return unions
            .sorted{ $0.count < $1.count }
            .map{ FiniteSubgroupStructure(allElements: $0) }
    }
}

public typealias ProductGroup<X: Group, Y: Group> = ProductMonoid<X, Y>

extension ProductGroup: Group where X: Group, Y: Group {
    public var inverse: ProductGroup<X, Y> {
        return ProductGroup(_1.inverse, _2.inverse)
    }
}

public protocol NormalSubgroup: Subgroup{}

public struct QuotientGroup<G, H: NormalSubgroup>: Group, _QuotientSet where G == H.Super {
    private let g: G
    public init(_ g: G) {
        self.g = g
    }
    
    public var representative: G {
        return g
    }
    
    public static func isEquivalent(_ x: G, _ y: G) -> Bool {
        return H.contains(x * y.inverse)
    }
    
    public static var identity: QuotientGroup<G, H> {
        return QuotientGroup(G.identity)
    }
    
    public var inverse: QuotientGroup<G, H> {
        return QuotientGroup(g.inverse)
    }
    
    public static func * (a: QuotientGroup<G, H>, b: QuotientGroup<G, H>) -> QuotientGroup<G, H> {
        return QuotientGroup(a.g * b.g)
    }
    
    public static var symbol: String {
        return "\(G.symbol)/\(H.symbol)"
    }
}
