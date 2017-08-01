import Foundation

public protocol Map {
    associatedtype Dom
    associatedtype Codom
    
    func appliedTo(_ x: Dom) -> Codom
}

public protocol ModuleHom: Map, Module {
    associatedtype Dom : Module
    associatedtype Codom : Module
}

