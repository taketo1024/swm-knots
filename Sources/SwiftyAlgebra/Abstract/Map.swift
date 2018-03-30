import Foundation

public protocol Map: SetType {
    associatedtype Domain: SetType
    associatedtype Codomain: SetType
    
    init(_ f: @escaping (Domain) -> Codomain)
    func applied(to x: Domain) -> Codomain
}

public extension Map {
    public static func ==(f: Self, g: Self) -> Bool {
        fatalError("cannot equate general maps.")
    }

    public var hashValue: Int {
        return 0
    }
    
    public var description: String {
        return "(map: \(Domain.symbol) -> \(Codomain.symbol))"
    }
    
    public static var symbol: String {
        return "Map(\(Domain.symbol), \(Codomain.symbol))"
    }
}

public extension Map where Domain == Codomain {
    public static var identity: Self {
        return Self { x in x }
    }
    
    public func composed(with f: Self) -> Self {
        return Self { x in self.applied(to: f.applied(to: x)) }
    }
    
    public static func ∘(g: Self, f: Self) -> Self {
        return g.composed(with: f)
    }
}

public extension SetType {
    public func apply<F: Map>(f: F) -> F.Codomain where Self == F.Domain {
        return f.applied(to: self)
    }
}

public struct SetMap<X: SetType, Y: SetType>: Map {
    public typealias Domain = X
    public typealias Codomain = Y
    
    private let f: (X) -> Y
    public init(_ f: @escaping (X) -> Y) {
        self.f = f
    }
    
    public func applied(to x: X) -> Y {
        return f(x)
    }
    
    public func composed<W>(with f: SetMap<W, X>) -> SetMap<W, Y> {
        return SetMap<W, Y> { x in self.applied(to: f.applied(to: x)) }
    }
    
    public var hashValue: Int {
        return 0
    }
    
    public static func ∘<Z>(g: SetMap<Y, Z>, f: SetMap<X, Y>) -> SetMap<X, Z> {
        return g.composed(with: f)
    }
}

public protocol End: Map, Monoid where Domain == Codomain {
    func composed(with f: Self) -> Self
    static func ∘(g: Self, f: Self) -> Self
}

public extension End {
    public static var identity: Self {
        return Self { x in x }
    }
    
    public static func *(g: Self, f: Self) -> Self {
        return g.composed(with: f)
    }
    
    public static func ∘(g: Self, f: Self) -> Self {
        return g.composed(with: f)
    }
}

public protocol Aut: End, Group { }
