//
//  ModuleCube.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/06/06.
//

import Foundation
import SwiftyMath

// An n-dim cube with Modules on all vertices I ∈ {0, 1}^n .

public struct ModuleCube<A: FreeModuleBasis, R: Ring> {
    public typealias Object = ModuleObject<A, R>
    
    public let dim: Int
    internal let objects: [IntList : Object]
    internal let edgeMaps: (IntList, IntList) -> FreeModuleHom<A, A, R>
    
    public init(dim n: Int, objects: [IntList : Object], edgeMaps: @escaping (IntList, IntList) -> FreeModuleHom<A, A, R>) {
        self.dim = n
        self.objects = objects
        self.edgeMaps = edgeMaps
    }
    
    public subscript(I: IntList) -> Object {
        return objects[I]!
    }
    
    public var bottom: Object {
        let I = IntList([0].repeated(dim))
        return self[I]
    }
    
    public var top: Object {
        let I = IntList([1].repeated(dim))
        return self[I]
    }
    
    public var vertices: [IntList] {
        return objects.keys.sorted()
    }
    
    public func targetVertices(from I: IntList) -> [(sign: R, vertex: IntList)] {
        return I.components.enumerated()
            .filter{ $0.element == 0 }
            .map { (i, _) in
                let c = I.components.enumerated().count{ (j, a) in j < i && a == 1 }
                let sign = R(from: (-1).pow(c))
                let vertex = IntList( I.components.replaced(at: i, with: 1))
                return (sign, vertex)
        }
    }
    
    public func edgeMap(from I0: IntList, to I1: IntList) -> FreeModuleHom<A, A, R> {
        return objects.contains(key: I0) && objects.contains(key: I1)
            ? self.edgeMaps(I0, I1)
            : .zero
    }
    
    public func d(_ I0: IntList) -> FreeModuleHom<A, A, R> {
        return self.targetVertices(from: I0).sum { (ε, I1) in
            ε * self.edgeMap(from: I0, to: I1)
        }
    }
    
    public func subCube(matching m: (Object.Summand) -> Bool) -> ModuleCube<A, R> {
        let objects = self.objects.mapValues{ obj in obj.subSummands(matching: m) }
        return ModuleCube(dim: dim, objects: objects, edgeMaps: edgeMaps)
    }
    
    public func fold() -> ModuleGrid1<A, R> {
        let data = vertices
            .group{ I in I.components.count{ $0 == 1 } }
            .mapValues{ list in
                list.reduce(.zeroModule) { (res, I) in res ⊕ self[I] }
            }
        
        return ModuleGrid1(data: data)
    }
    
    public func describe(_ I: IntList) {
        print("\(I): ", terminator: "")
        self[I].describe()
        print()
    }
    
    public func describeAll() {
        vertices.forEach{ I in
            describe(I)
        }
        print()
    }
}
