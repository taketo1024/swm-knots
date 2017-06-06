import Foundation

public typealias FreeModuleBase = Hashable

public struct FreeModule<A: FreeModuleBase, _R: Ring>: Module {
    public typealias R = _R
    
    public let basis: [A]
    internal let comps: [R]
    internal let table: [A: R]
    
    // root initializer
    public init(basis: [A], components: [R]) {
        guard basis.count == components.count else {
            fatalError("#basis (\(basis.count)) != #components (\(components.count))")
        }
        self.basis = basis
        self.comps = components
        self.table = Dictionary(Array(zip(basis, components)))
    }
    
    public init(_ table: [A : R]) {
        let basis = Array(table.keys)
        let comps = basis.map{ table[$0] ?? R.zero }
        self.init(basis: basis, components: comps)
    }
    
    // generates a basis element
    public init(_ a: A) {
        self.init(basis: [a], components: [1])
    }
    
    public static var zero: FreeModule<A, R> {
        return FreeModule<A, R>.init(basis: [], components: [])
    }
    
    public func component(forBasisElement a: A) -> R {
        return table[a] ?? R.zero
    }
    
    public func components(forBasis basis: [A]) -> [R] {
        return basis.map{ component(forBasisElement: $0) }
    }
    
    public static func == (a: FreeModule<A, R>, b: FreeModule<A, R>) -> Bool {
        return a.table == b.table // bases need not be in same order.
    }
    
    public static func + (a: FreeModule<A, R>, b: FreeModule<A, R>) -> FreeModule<A, R> {
        let basis = (a.basis + b.basis).unique()
        let comps = basis.map { x in a.component(forBasisElement: x) + b.component(forBasisElement: x) }
        return FreeModule<A, R>(basis: basis, components: comps)
    }
    
    public static prefix func - (a: FreeModule<A, R>) -> FreeModule<A, R> {
        let comps = a.comps.map{-$0}
        return FreeModule<A, R>(basis: a.basis, components: comps)
    }
    
    public static func * (r: R, a: FreeModule<A, R>) -> FreeModule<A, R> {
        let comps = a.comps.map{r * $0}
        return FreeModule<A, R>(basis: a.basis, components: comps)
    }
    
    public static func * (a: FreeModule<A, R>, r: R) -> FreeModule<A, R> {
        let comps = a.comps.map{$0 * r}
        return FreeModule<A, R>(basis: a.basis, components: comps)
    }
    
    public var description: String {
        let sum: String = basis.enumerated()
            .map {($1, comps[$0])}
            .filter{ (_, r) in r != R.zero }
            .map { (a, r) in (r == R.identity) ? "\(a)" : "\(r)\(a)" }
            .joined(separator: " + ")
        
        return sum.isEmpty ? "0" : sum
    }
    
    public static var symbol: String {
        return "FM(\(R.symbol))"
    }
    
    public var hashValue: Int {
        return comps.count > 0 ? comps[0].hashValue : 0
    }
    
    public static func generateElements<n:_Int, m:_Int>(basis: [A], matrix A: Matrix<R, n, m>) -> [FreeModule<A, R>] {
        return (0 ..< A.cols).map { FreeModule<A, R>(basis: basis, components: A.colArray($0)) }
    }
}

public struct FreeZeroModule<A: FreeModuleBase, _R: Ring>: Submodule {
    public typealias Super = FreeModule<A, R>
    public typealias R = _R
    
    public init(_ m: Super) {}
    
    public var asSuper: Super {
        return Super.zero
    }
    
    public static func contains(_ g: FreeModule<A, _R>) -> Bool {
        return g == Super.zero
    }
    
    public static var symbol: String {
        return "{0}"
    }
}
