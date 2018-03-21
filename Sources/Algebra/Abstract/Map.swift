import Foundation

public protocol Map {
    associatedtype Domain: SetType
    associatedtype Codomain: SetType
    func applied(to x: Domain) -> Codomain
    func equals(_ g: Self, forElements: [Domain]) -> Bool
}

public extension Map {
    public func equals(_ g: Self, forElements xs: [Domain]) -> Bool {
        return xs.forAll{ x in self.applied(to: x) == g.applied(to: x) }
    }

    public var description: String {
        return "(map: \(Domain.symbol) -> \(Codomain.symbol))"
    }
    
    public static var symbol: String {
        return "Map(\(Domain.symbol), \(Codomain.symbol))"
    }
}

public extension SetType {
    public func apply<F: Map>(f: F) -> F.Codomain where Self == F.Domain {
        return f.applied(to: self)
    }
}
