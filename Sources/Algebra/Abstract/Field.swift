import Foundation

public protocol Field: EuclideanRing {
    init(from r: 𝐐)
}

public extension Field {
    public init(from r: 𝐐) {
        fatalError("TODO")
    }
    
    public var normalizeUnit: Self {
        return self.inverse!
    }
    
    public var degree: Int {
        return self == .zero ? 0 : 1
    }
    
    public static func / (a: Self, b: Self) -> Self {
        return a * b.inverse!
    }
    
    public func pow(_ n: Int) -> Self {
        if n >= 0 {
            return (0 ..< n).reduce(.identity){ (res, _) in self * res }
        } else {
            return (0 ..< -n).reduce(.identity){ (res, _) in inverse! * res }
        }
    }
    
    public static func eucDiv(_ a: Self, _ b: Self) -> (q: Self, r: Self) {
        return (a/b, 0)
    }
    
    public static var isField: Bool {
        return true
    }
}

public protocol Subfield: Field, Subring {}

// TODO merge with QuotientRing using conditional conformance `where I: MaximalIdeal`
// public struct QuotientField<R, I>: Field, _QuotientRing where I: Ideal, R == I.Super {
public struct QuotientField<R, I>: Field, _QuotientRing where I: Ideal, R == I.Super {
    public typealias Sub = I
    
    internal let r: R
    
    public init(_ r: R) {
        self.r = I.reduced(r)
    }
    
    public var representative: R {
        return r
    }
}

public protocol _FieldHom: _RingHom where Domain: Field, Codomain: Field {}

public struct FieldHom<X: Field, Y: Field>: _FieldHom {
    public typealias Domain = X
    public typealias Codomain = Y
    
    private let f: (X) -> Y
    public init(_ f: @escaping (X) -> Y) {
        self.f = f
    }
    
    public func applied(to x: X) -> Y {
        return f(x)
    }
    
    public func composed<W>(with f: FieldHom<W, X>) -> FieldHom<W, Y> {
        return FieldHom<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘<Z>(g: FieldHom<Y, Z>, f: FieldHom<X, Y>) -> FieldHom<X, Z> {
        return g.composed(with: f)
    }
}
