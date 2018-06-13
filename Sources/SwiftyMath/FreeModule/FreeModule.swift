import Foundation

public struct FreeModule<A: BasisElementType, R: Ring>: Module {
    public typealias CoeffRing = R
    public typealias Basis = [A]
    
    public let elements: [A: R]
    
    // root initializer
    public init(_ elements: [A : R]) {
        self.elements = elements.filter{ $0.value != .zero }
    }
    
    public init<S: Sequence>(_ elements: S) where S.Element == (A, R) {
        let dict = Dictionary(pairs: elements)
        self.init(dict)
    }
    
    public init(basis: Basis, components: [R]) {
        assert(basis.count == components.count)
        self.init(Dictionary(pairs: zip(basis, components)))
    }
    
    public init<n>(basis: Basis, vector: _ColVector<n, R>) {
        assert(basis.count == vector.rows)
        self.init(Dictionary(pairs: zip(basis, vector.grid)))
    }
    
    // generates a basis element
    public init(_ a: A) {
        self.init(a, .identity)
    }
    
    public init(_ a: A, _ r: R) {
        self.init([(a, r)])
    }
    
    public subscript(a: A) -> R {
        return elements[a] ?? .zero
    }
    
    public var degree: Int {
        return elements.anyElement?.0.degree ?? 0
    }
    
    public var basis: Basis {
        return elements.keys.sorted().toArray()
    }
    
    public var components: [R] {
        return elements.keys.sorted().map{ self[$0] }
    }
    
    public func factorize(by list: [A]) -> [R] {
        return list.map{ self[$0] }
    }
    
    public var isSingle: Bool {
        return elements.count == 1 && elements.anyElement!.value == .identity
    }
    
    public static var zero: FreeModule<A, R> {
        return FreeModule([])
    }
    
    public func mapBasis<A2>(_ f: (A) -> A2) -> FreeModule<A2, R> {
        return map { (a, r) in FreeModule<A2, R>(f(a), r) }
    }
    
    public func mapValues<R2>(_ f: (R) -> R2) -> FreeModule<A, R2> {
        return FreeModule<A, R2>(elements.mapValues(f))
    }
    
    public func map<A2, R2>(_ f: (A, R) -> FreeModule<A2, R2>) -> FreeModule<A2, R2> {
        return self.elements.map{ (a, r) in f(a, r) }.sumAll()
    }
    
    public static func == (a: FreeModule<A, R>, b: FreeModule<A, R>) -> Bool {
        return a.elements == b.elements
    }
    
    public static func + (a: FreeModule<A, R>, b: FreeModule<A, R>) -> FreeModule<A, R> {
        var d = a.elements
        for (a, r) in b.elements {
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
    
    public static func sum(_ elements: [FreeModule<A, R>]) -> FreeModule<A, R> {
        var sum = [A : R]()
        elements.forEach{ x in
            sum.merge(x.elements) { (r1, r2) in r1 + r2 }
        }
        return FreeModule(sum)
    }
    
    public static func wrap(_ a: A) -> FreeModule<A, R> {
        return FreeModule(a)
    }
    
    public var description: String {
        return Format.terms("+", basis.map { a in (self[a], a.description, 1) })
    }
    
    public static var symbol: String {
        return "FreeMod(\(R.symbol))"
    }
    
    public var hashValue: Int {
        return (self == .zero) ? 0 : 1
    }
}

public func *<A, R>(v: [A], a: Matrix<R>) -> [FreeModule<A, R>] {
    return v.map{ FreeModule<A, R>($0) } * a
}

public func *<A, R>(v: [FreeModule<A, R>], a: Matrix<R>) -> [FreeModule<A, R>] {
    assert(v.count == a.rows)
    return (0 ..< a.cols).map{ j in
        a.nonZeroComponents(ofCol: j).sum{ c in
            v[c.row] * c.value
        }
    }
}

extension FreeModule: VectorSpace where R: Field {}

public func pair<A, R>(_ x: FreeModule<A, R>, _ y: FreeModule<Dual<A>, R>) -> R {
    return x.elements.reduce(.zero) { (res, next) -> R in
        let (a, r) = next
        return res + r * y[Dual(a)]
    }
}

public func pair<A, R>(_ x: FreeModule<Dual<A>, R>, _ y: FreeModule<A, R>) -> R {
    return pair(y, x)
}

extension FreeModule: Codable where A: Codable, R: Codable {
    enum CodingKeys: String, CodingKey {
        case elements
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let elements = try c.decode([A : R].self, forKey: .elements)
        self.init(elements)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(elements, forKey: .elements)
    }
}
