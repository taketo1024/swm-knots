import Foundation

public typealias FreeModuleBase = Hashable

public struct FreeModule<A: FreeModuleBase, _R: Ring>: Module, Sequence {
    public typealias R = _R
    
    public let basis: [A]
    internal let elements: [A: R]
    
    // root initializer
    public init(basis: [A], elements: [A : R]) {
        self.basis = basis
        self.elements = elements
    }
    
    public init(basis: [A], components: [R]) {
        guard basis.count == components.count else {
            fatalError("#basis (\(basis.count)) != #components (\(components.count))")
        }
        self.init(basis: basis, elements: Dictionary(pairs: zip(basis, components)))
    }
    
    public init(_ elements: [(A, R)]) {
        self.init(basis: elements.map{$0.0}, elements: Dictionary(pairs: elements))
    }
    
    // generates a basis element
    public init(_ a: A) {
        self.init([(a, 1)])
    }
    
    public subscript(a: A) -> R {
        return elements[a] ?? R.zero
    }
    
    public func components(correspondingTo list: [A]) -> [R] {
        return list.map{ self[$0] }
    }
    
    public static var zero: FreeModule<A, R> {
        return FreeModule<A, R>.init([])
    }
    
    public func mapComponents<R2: Ring>(_ f: (R) -> R2) -> FreeModule<A, R2> {
        return FreeModule<A, R2>(basis: basis, elements: elements.mapValues(transform: f))
    }
    
    public func makeIterator() -> DictionaryIterator<A, R> {
        return elements.makeIterator()
    }
    
    public static func == (a: FreeModule<A, R>, b: FreeModule<A, R>) -> Bool {
        return a.elements == b.elements // bases need not be in same order.
    }
    
    public static func + (a: FreeModule<A, R>, b: FreeModule<A, R>) -> FreeModule<A, R> {
        let basis = (a.basis + b.basis).unique()
        let elements = Dictionary(keys: basis) { a[$0] + b[$0] }
        return FreeModule<A, R>(basis: basis, elements: elements)
    }
    
    public static prefix func - (a: FreeModule<A, R>) -> FreeModule<A, R> {
        return FreeModule<A, R>(basis: a.basis, elements: a.elements.mapValues{ -$0 })
    }
    
    public static func * (r: R, a: FreeModule<A, R>) -> FreeModule<A, R> {
        return FreeModule<A, R>(basis: a.basis, elements: a.elements.mapValues{ r * $0 })
    }
    
    public static func * (a: FreeModule<A, R>, r: R) -> FreeModule<A, R> {
        return FreeModule<A, R>(basis: a.basis, elements: a.elements.mapValues{ $0 * r })
    }
    
    public var description: String {
        let sum: String = basis.map {($0, self[$0])}
            .filter{ (_, r) in r != R.zero }
            .map { (a, r) in (r == R.identity) ? "\(a)" : "\(r)\(a)" }
            .joined(separator: " + ")
        
        return sum.isEmpty ? "0" : sum
    }
    
    public static var symbol: String {
        return "FM(\(R.symbol))"
    }
    
    public var hashValue: Int {
        return basis.count > 0 ? self[basis.first!].hashValue : 0
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

public struct Dual<A: FreeModuleBase>: FreeModuleBase, CustomStringConvertible {
    public let base: A
    public init(_ a: A) {
        base = a
    }
    
    public var hashValue: Int {
        return base.hashValue
    }
    
    public static func ==(a: Dual<A>, b: Dual<A>) -> Bool {
        return a.base == b.base
    }
    
    public var description: String {
        return "\(base)*"
    }
}

public extension FreeModule {
    public func evaluate(_ f: FreeModule<Dual<A>, R>) -> R {
        return self.reduce(R.zero) { (res, next) -> R in
            let (a, r) = next
            return res + r * f[Dual(a)]
        }
    }
    
    public func evaluate<B: FreeModuleBase>(_ b: FreeModule<B, R>) -> R where A == Dual<B> {
        return b.reduce(R.zero) { (res, next) -> R in
            let (a, r) = next
            return res + r * self[Dual(a)]
        }
    }
}
