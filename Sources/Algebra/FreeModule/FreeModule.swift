import Foundation

public struct FreeModule<A: FreeModuleBase, R: Ring>: Module, Sequence {
    public typealias CoeffRing = R
    public typealias Basis = [A]
    
    internal let elements: [A: R]
    
    // root initializer
    public init(_ elements: [A : R]) {
        self.elements = elements.filter{ $0.value != 0 }
    }
    
    public init<S: Sequence>(_ elements: S) where S.Element == (A, R) {
        let dict = Dictionary(pairs: elements)
        self.init(dict)
    }
    
    public init(basis: Basis, components: [R]) {
        assert(basis.count == components.count)
        self.init(Dictionary(pairs: zip(basis, components)))
    }
    
    public init<n>(basis: Basis, vector: ColVector<n, R>) {
        assert(basis.count == vector.rows)
        self.init(Dictionary(pairs: zip(basis, vector.grid)))
    }
    
    // generates a basis element
    public init(_ a: A) {
        self.init(a, 1)
    }
    
    public init(_ a: A, _ r: R) {
        self.init([(a, r)])
    }
    
    public subscript(a: A) -> R {
        return elements[a] ?? .zero
    }
    
    public var degree: Int {
        return anyElement?.0.degree ?? 0
    }
    
    public var basis: Basis {
        return elements.keys.toArray()
    }
    
    public func factorize(by list: Basis) -> [R] {
        return list.map{ self[$0] }
    }
    
    public static var zero: FreeModule<A, R> {
        return FreeModule([])
    }
    
    public func mapValues<R2: Ring>(_ f: (R) -> R2) -> FreeModule<A, R2> {
        return FreeModule<A, R2>(elements.mapValues(f))
    }
    
    public func makeIterator() -> AnyIterator<(A, R)> {
        return AnyIterator(elements.lazy.map{ (a, r) in (a, r) }.makeIterator())
    }
    
    public static func == (a: FreeModule<A, R>, b: FreeModule<A, R>) -> Bool {
        return a.elements == b.elements
    }
    
    public static func + (a: FreeModule<A, R>, b: FreeModule<A, R>) -> FreeModule<A, R> {
        var d: [A : R] = a.elements
        for (a, r) in b {
            d[a] = d[a, default: .zero] + r
        }
        return FreeModule<A, R>(d)
    }
    
    public static prefix func - (a: FreeModule<A, R>) -> FreeModule<A, R> {
        return FreeModule<A, R>(a.elements.mapValues{ -$0 })
    }
    
    public static func * (r: R, a: FreeModule<A, R>) -> FreeModule<A, R> {
        return FreeModule<A, R>(a.elements.mapValues{ r * $0 })
    }
    
    public static func * (a: FreeModule<A, R>, r: R) -> FreeModule<A, R> {
        return FreeModule<A, R>(a.elements.mapValues{ $0 * r })
    }
    
    public static func ⊕<B>(x: FreeModule<A, R>, y: FreeModule<B, R>) -> FreeModule<Sum<A, B>, R> {
        let elements = x.map { (a, r) -> (Sum<A, B>, R) in (Sum._1(a), r) }
                     + y.map { (b, r) -> (Sum<A, B>, R) in (Sum._2(b), r) }

        return FreeModule<Sum<A, B>, R>(elements)
    }
    
    public static func ⊗<B>(x: FreeModule<A, R>, y: FreeModule<B, R>) -> FreeModule<Tensor<A, B>, R> {
        let elements = x.basis.allCombinations(with: y.basis).map{ (a, b) -> (Tensor<A, B>, R) in
            return (a ⊗ b, x[a] * y[b])
        }
        return FreeModule<Tensor<A, B>, R>(elements)
    }
    
    public var description: String {
        let list = (A.self == Int.self)
            ? self.map { (a, r) in (r == .identity) ? "e\(a)" : "\(r)e\(a)" }
            : self.map { (a, r) in (r == .identity) ? "\(a)" : "\(r)\(a)" }
        
        return list.isEmpty ? "0" : list.joined(separator: " + ")
    }
    
    public static var symbol: String {
        return "FreeMod(\(R.symbol))"
    }
    
    public var hashValue: Int {
        return (self == .zero) ? 0 : 1
    }
}

public func pair<A, R>(_ x: FreeModule<A, R>, _ y: FreeModule<Dual<A>, R>) -> R {
    return x.reduce(.zero) { (res, next) -> R in
        let (a, r) = next
        return res + r * y[Dual(a)]
    }
}

public func pair<A, R>(_ x: FreeModule<Dual<A>, R>, _ y: FreeModule<A, R>) -> R {
    return pair(y, x)
}
