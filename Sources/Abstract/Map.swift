import Foundation

public protocol Map {
    associatedtype Domain
    associatedtype Codomain
    func appliedTo(_ x: Domain) -> Codomain
}

public protocol ModuleHom: Map, Module where Domain: Module, Codomain : Module {}

