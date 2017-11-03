import Foundation

public protocol Map {
    associatedtype Domain: SetType
    associatedtype Codomain: SetType
    func appliedTo(_ x: Domain) -> Codomain
}

public extension Map {
    public var description: String {
        return "(map: \(Domain.symbol) -> \(Codomain.symbol))"
    }
    
    public static var symbol: String {
        return "Map(\(Domain.symbol), \(Codomain.symbol))"
    }
}

public protocol ModuleHom: Map, Module where Domain: Module, Codomain : Module {}

public extension ModuleHom {
    public static var symbol: String {
        return "Hom_\(CoeffRing.symbol)(\(Domain.symbol), \(Codomain.symbol))"
    }
}
