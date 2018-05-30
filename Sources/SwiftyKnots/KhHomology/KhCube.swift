//
//  KhCube.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/16.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public struct KhCube {
    public struct Vertex {
        public let state: KauffmanState
        public let components: [Link.Component]
        public let basis: [KhTensorElement]
    }
    
    public let vertices: [KauffmanState : Vertex]
    private let minEdgeId: Int
    
    public init(_ L: Link) {
        self.vertices = Dictionary(keys: L.allStates) { s -> Vertex in
            let sL = L.spliced(by: s)
            let comps = sL.components
            let basis = KhTensorElement.generateBasis(state: s, power: comps.count)
            return Vertex(state: s, components: comps, basis: basis)
        }
        
        self.minEdgeId = L.edges.map{ $0.id }.min() ?? -1
    }
    
    public subscript(s: KauffmanState) -> Vertex {
        return vertices[s]!
    }
    
    public func vertices(degree: Int) -> [Vertex] {
        return vertices.values.filter{ $0.state.degree == degree }
    }
    
    public func basis(degree: Int) -> [KhTensorElement] {
        return vertices(degree: degree).flatMap { v in v.basis }
    }
    
    public func reducedBasis(degree: Int) -> [KhTensorElement] {
        return vertices(degree: degree).flatMap { v -> [KhTensorElement] in
            if let i = v.components.index(where: { $0.edges.contains{ $0.id == minEdgeId } }) {
                return v.basis.filter{ t in t.factors[i] == .X }
            } else {
                return v.basis
            }
        }
    }
    
    public func d<R: Ring>(_ type: R.Type) -> FreeModuleHom<KhTensorElement, KhTensorElement, R> {
        return d(type, KhBasisElement.μ, KhBasisElement.Δ)
    }
    
    public func d_Lee<R: Ring>(_ type: R.Type) -> FreeModuleHom<KhTensorElement, KhTensorElement, R> {
        return d(type, KhBasisElement.μ_Lee, KhBasisElement.Δ_Lee)
    }
    
    public func d_BN<R: Ring>(_ type: R.Type) -> FreeModuleHom<KhTensorElement, KhTensorElement, R> {
        return d(type, KhBasisElement.μ_BN, KhBasisElement.Δ_BN)
    }
    
    public func d<R: Ring>(_ type: R.Type, _ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>) -> FreeModuleHom<KhTensorElement, KhTensorElement, R> {
        return FreeModuleHom { (x: KhTensorElement) in
            let s = x.state
            return s.next.sum { (sgn, next) in
                let (c1, c2) = (self[s].components, self[next].components)
                let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
                
                switch (d1.count, d2.count) {
                case (2, 1): // apply μ
                    let (i1, i2, j) = (c1.index(of: d1[0])!, c1.index(of: d1[1])!, c2.index(of: d2[0])!)
                    return R(from: sgn) * x.product(μ, (i1, i2), j, next)
                    
                case (1, 2): // apply Δ
                    let (i, j1, j2) = (c1.index(of: d1[0])!, c2.index(of: d2[0])!, c2.index(of: d2[1])!)
                    return R(from: sgn) * x.coproduct(Δ, i, (j1, j2), next)
                    
                default:
                    fatalError()
                }
            }
        }
    }
}

public extension Link {
    public var KhCube: SwiftyKnots.KhCube {
        if let val = _KhCube.value {
            return val
        }
        
        let val = SwiftyKnots.KhCube(self)
        _KhCube.value = val
        return val
    }
}

