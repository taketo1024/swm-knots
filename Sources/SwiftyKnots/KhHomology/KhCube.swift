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
    
    public func targets(_ v: Vertex) -> [(sign: Int, vertex: Vertex)] {
        let s = v.state
        return s.bits
            .filter{ $0.value == .O }
            .map { (i, _) -> (Int, Vertex) in
                let sgn = (-1).pow( s.bits.count{ (j, a) in j < i && a == .I } )
                let next = KauffmanState(s.bits.replaced(at: i, with: .I))
                return (sgn, self[next])
        }
    }
    
    public func edgeMap<R>(_ type: R.Type, _ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>) -> FreeModuleHom<KhTensorElement, KhTensorElement, R> {
        
        return FreeModuleHom { (x: KhTensorElement) -> FreeModule<KhTensorElement, R> in
            let v0 = self[x.state]
            return self.targets(v0).sum { (sgn, v1) in
                let (c1, c2) = (v0.components, v1.components)
                let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
                
                switch (d1.count, d2.count) {
                case (2, 1): // apply μ
                    let (i1, i2, j) = (c1.index(of: d1[0])!, c1.index(of: d1[1])!, c2.index(of: d2[0])!)
                    return R(from: sgn) * x.product(μ, (i1, i2), j, v1.state)
                    
                case (1, 2): // apply Δ
                    let (i, j1, j2) = (c1.index(of: d1[0])!, c2.index(of: d2[0])!, c2.index(of: d2[1])!)
                    return R(from: sgn) * x.coproduct(Δ, i, (j1, j2), v1.state)
                    
                default:
                    fatalError()
                }
            }
        }
    }
    
    public func d<R>(_ type: R.Type, _ bidegree: (Int, Int), _ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>) -> ChainMap2<KhTensorElement, KhTensorElement, R> {
        return ChainMap2(bidegree: bidegree) { (_, _) in self.edgeMap(type, μ, Δ) }
    }

    public func d<R>(_ type: R.Type) -> ChainMap2<KhTensorElement, KhTensorElement, R> {
        return d(type, (1, 0), KhBasisElement.μ, KhBasisElement.Δ)
    }
    
    public func d_Lee<R>(_ type: R.Type) -> ChainMap2<KhTensorElement, KhTensorElement, R> {
        return d(type, (1, 4), KhBasisElement.μ_Lee, KhBasisElement.Δ_Lee)
    }
    
    public func d_BN<R>(_ type: R.Type) -> ChainMap2<KhTensorElement, KhTensorElement, R> {
        return d(type, (1, 2), KhBasisElement.μ_BN, KhBasisElement.Δ_BN)
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

