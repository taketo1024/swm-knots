//
//  ModuleCube.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/06/06.
//

import Foundation
import SwiftyMath

// An n-dim cube with Modules on all vertices I ∈ {0, 1}^n .

public struct ModuleCube<A: BasisElementType, R: EuclideanRing> {
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
        if objects.contains(key: I0) && objects.contains(key: I1) {
            return FreeModuleHom{ (x: FreeModule<A, R>) in
                self[I0].contains(x) ? self.edgeMaps(I0, I1).applied(to: x) : .zero
            }
        } else {
            return .zero
        }
    }
    
    public func subCube(matching m: (Object.Summand) -> Bool) -> ModuleCube<A, R> {
        let objects = self.objects.mapValues{ obj in obj.subSummands(matching: m) }
        return ModuleCube(dim: dim, objects: objects, edgeMaps: edgeMaps)
    }
    
    public func asChainComplex() -> ChainComplex<A, R> {
        let group = vertices.group{ I in I.components.count{ $0 == 1 } }
        let list = group
            .map{ (i, list) -> (Int, Object?) in
                let sum = list.reduce(.zeroModule) { (res, I) in res ⊕ self[I] }
                return (i, sum)
        }
        let base = ModuleGrid1(list: list, default: .zeroModule)
        let d = ChainMap(degree: 1) { i -> FreeModuleHom<A, A, R> in
            guard let Is = group[i] else {
                return .zero
            }
            return Is.sum { I0 -> FreeModuleHom<A, A, R> in
                self.targetVertices(from: I0).sum { (ε, I1) in
                    ε * self.edgeMap(from: I0, to: I1)
                }
            }
        }
        return ChainComplex(base: base, differential: d)
    }
    
    public func describe(_ I: IntList) {
        print("\(I): \(self[I])")
    }
    
    public func describeAll() {
        vertices.forEach{ I in
            describe(I)
        }
        print()
    }
}
