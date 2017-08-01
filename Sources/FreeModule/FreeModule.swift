import Foundation

public protocol FreeModuleBase: SetType {}

public struct FreeModule<_R: Ring, A: FreeModuleBase>: Module, Sequence {
    public typealias R = _R
    
    public let basis: [A]
    internal let elements: [A: R]
    
    // root initializer
    internal init(basis: [A], elements: [A : R]) {
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
    
    public static var zero: FreeModule<R, A> {
        return FreeModule<R, A>.init([])
    }
    
    public func mapComponents<R2: Ring>(_ f: (R) -> R2) -> FreeModule<R2, A> {
        return FreeModule<R2, A>(basis: basis, elements: elements.mapValues(transform: f))
    }
    
    public func makeIterator() -> DictionaryIterator<A, R> {
        return elements.makeIterator()
    }
    
    public static func == (a: FreeModule<R, A>, b: FreeModule<R, A>) -> Bool {
        return a.elements == b.elements // bases need not be in same order.
    }
    
    public static func + (a: FreeModule<R, A>, b: FreeModule<R, A>) -> FreeModule<R, A> {
        let basis = (a.basis + b.basis).unique()
        let elements = Dictionary(keys: basis) { a[$0] + b[$0] }
        return FreeModule<R, A>(basis: basis, elements: elements)
    }
    
    public static prefix func - (a: FreeModule<R, A>) -> FreeModule<R, A> {
        return FreeModule<R, A>(basis: a.basis, elements: a.elements.mapValues{ -$0 })
    }
    
    public static func * (r: R, a: FreeModule<R, A>) -> FreeModule<R, A> {
        return FreeModule<R, A>(basis: a.basis, elements: a.elements.mapValues{ r * $0 })
    }
    
    public static func * (a: FreeModule<R, A>, r: R) -> FreeModule<R, A> {
        return FreeModule<R, A>(basis: a.basis, elements: a.elements.mapValues{ $0 * r })
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
    
    public static func generateElements<n:_Int, m:_Int>(basis: [A], matrix A: Matrix<R, n, m>) -> [FreeModule<R, A>] {
        return (0 ..< A.cols).map { FreeModule<R, A>(basis: basis, components: A.colArray($0)) }
    }
}

public struct FreeZeroModule<A: FreeModuleBase, _R: Ring>: Submodule {
    public typealias Super = FreeModule<R, A>
    public typealias R = _R
    
    public init(_ m: Super) {}
    
    public var asSuper: Super {
        return Super.zero
    }
    
    public static func contains(_ g: FreeModule<R, A>) -> Bool {
        return g == Super.zero
    }
    
    public static var symbol: String {
        return "{0}"
    }
}

public struct Dual<A: FreeModuleBase>: FreeModuleBase {
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
    public func evaluate(_ f: FreeModule<R, Dual<A>>) -> R {
        return self.reduce(R.zero) { (res, next) -> R in
            let (a, r) = next
            return res + r * f[Dual(a)]
        }
    }
    
    public func evaluate<B: FreeModuleBase>(_ b: FreeModule<R, B>) -> R where A == Dual<B> {
        return b.reduce(R.zero) { (res, next) -> R in
            let (a, r) = next
            return res + r * self[Dual(a)]
        }
    }
}

public struct Tensor<A: FreeModuleBase, B: FreeModuleBase>: FreeModuleBase {
    public let _1: A
    public let _2: B
    public init(_ a: A, _ b: B) {
        _1 = a
        _2 = b
    }
    
    public var hashValue: Int {
        return _1.hashValue &* 31 &+ _2.hashValue % 31
    }
    
    public static func ==(t1: Tensor<A, B>, t2: Tensor<A, B>) -> Bool {
        return t1._1 == t2._1 && t1._2 == t2._2
    }
    
    public var description: String {
        return "\(_1)⊗\(_2)"
    }
}

public func ⊗<A: FreeModuleBase, B: FreeModuleBase>(a: A, b: B) -> Tensor<A, B> {
    return Tensor(a, b)
}

public func ⊗<R: Ring, A: FreeModuleBase, B: FreeModuleBase>(x: FreeModule<R, A>, y: FreeModule<R, B>) -> FreeModule<R, Tensor<A, B>> {
    let elements = x.basis.pairs(with: y.basis).map{ (a, b) -> (Tensor<A, B>, R) in
        return (a⊗b, x[a] * y[b])
    }
    return FreeModule(elements)
}
