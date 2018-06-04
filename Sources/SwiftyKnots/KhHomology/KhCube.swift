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
        public let basis: [KhBasisElement]
    }
    
    public let vertices: [KauffmanState : Vertex]
    private let minEdgeId: Int
    
    public init(_ L: Link) {
        self.vertices = Dictionary(keys: L.allStates) { s -> Vertex in
            let sL = L.spliced(by: s)
            let comps = sL.components
            let basis = KhBasisElement.generateBasis(state: s, power: comps.count)
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
    
    public func basis(degree: Int) -> [KhBasisElement] {
        return vertices(degree: degree).flatMap { v in v.basis }
    }
    
    public func reducedBasis(degree: Int) -> [KhBasisElement] {
        return vertices(degree: degree).flatMap { v -> [KhBasisElement] in
            if let i = v.components.index(where: { $0.edges.contains{ $0.id == minEdgeId } }) {
                return v.basis.filter{ t in t.factors[i] == .X }
            } else {
                return v.basis
            }
        }
    }
    
    public func targetVertices(from v: Vertex) -> [(sign: Int, vertex: Vertex)] {
        let s = v.state
        return s.bits
            .filter{ $0.value == .O }
            .map { (i, _) -> (Int, Vertex) in
                let sgn = (-1).pow( s.bits.count{ (j, a) in j < i && a == .I } )
                let next = KauffmanState(s.bits.replaced(at: i, with: .I))
                return (sgn, self[next])
        }
    }
    
    internal typealias E = KhBasisElement.E
    internal typealias Product<R: Ring> = (E, E) -> [(E, R)]
    internal typealias Coproduct<R: Ring> = (E) -> [(E, E, R)]

    internal func mergeMap<R>(from v0: Vertex, to v1: Vertex, _ μ: @escaping Product<R>) -> FreeModuleHom<KhBasisElement, KhBasisElement, R> {
        let (c1, c2) = (v0.components, v1.components)
        let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
        
        assert((d1.count, d2.count) == (2, 1))
        
        let (i1, i2) = (c1.index(of: d1[0])!, c1.index(of: d1[1])!)
        let j = c2.index(of: d2[0])!
        
        return FreeModuleHom { (x: KhBasisElement) in
            let (e1, e2) = (x.factors[i1], x.factors[i2])
            
            return μ(e1, e2).sum { (e, a) in
                var factors = x.factors
                factors.remove(at: i2)
                factors.remove(at: i1)
                factors.insert(e, at: j)
                let t = KhBasisElement(state: v1.state, factors: factors)
                return FreeModule(t, a)
            }
        }
    }
    
    internal func splitMap<R>(from v0: Vertex, to v1: Vertex, _ Δ: @escaping Coproduct<R>) -> FreeModuleHom<KhBasisElement, KhBasisElement, R> {
        let (c1, c2) = (v0.components, v1.components)
        let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
        
        assert((d1.count, d2.count) == (1, 2))
        
        let i = c1.index(of: d1[0])!
        let (j1, j2) = (c2.index(of: d2[0])!, c2.index(of: d2[1])!)

        return FreeModuleHom { (x: KhBasisElement) in
            let e = x.factors[i]
            return Δ(e).sum { (e1, e2, a)  in
                var factors = x.factors
                factors.remove(at: i)
                factors.insert(e1, at: j1)
                factors.insert(e2, at: j2)
                let t = KhBasisElement(state: v1.state, factors: factors)
                return FreeModule(t, a)
            }
        }
    }
    
    internal func edgeMap<R>(from v0: Vertex, _ μ: @escaping Product<R>, _ Δ: @escaping Coproduct<R>) -> FreeModuleHom<KhBasisElement, KhBasisElement, R> {
        
        return targetVertices(from: v0).sum { (sgn, v1) in
            let ε = R(from: sgn)
            switch v1.components.count - v0.components.count {
            case -1: return ε * mergeMap(from: v0, to: v1, μ)
            case  1: return ε * splitMap(from: v0, to: v1, Δ)
            default: fatalError()
            }
        }
    }
    
    internal func d<R>(_ μ: @escaping Product<R>, _ Δ: @escaping Coproduct<R>) -> FreeModuleHom<KhBasisElement, KhBasisElement, R> {
        return FreeModuleHom{ (x: KhBasisElement) in
            self.edgeMap(from: self[x.state], μ, Δ).applied(to: x)
        }
    }
    
    public func d<R>(_ type: R.Type) -> FreeModuleHom<KhBasisElement, KhBasisElement, R> {
        let μ: Product<R> = { (e1, e2) in
            switch (e1, e2) {
            case (.I, .I): return [(.I, .identity)]
            case (.I, .X), (.X, .I): return [(.X, .identity)]
            case (.X, .X): return []
            }
        }
        
        let Δ: Coproduct<R> = { e in
            switch e {
            case .I: return [(.I, .X, .identity), (.X, .I, .identity)]
            case .X: return [(.X, .X, .identity)]
            }
        }
        
        return d(μ, Δ)
    }
    
    public func d_Lee<R>(_ type: R.Type) -> FreeModuleHom<KhBasisElement, KhBasisElement, R> {
        let μ: Product<R> = { (e1, e2) in
            switch (e1, e2) {
            case (.X, .X): return [(.I, .identity)]
            default: return []
            }
        }
        
        let Δ: Coproduct<R> = { e in
            switch e {
            case .X: return [(.I, .I, .identity)]
            default: return []
            }
        }
        
        return d(μ, Δ)
    }

    public func d_BN<R>(_ type: R.Type) -> FreeModuleHom<KhBasisElement, KhBasisElement, R> {
        let μ: Product<R> = { (e1, e2) in
            switch (e1, e2) {
            case (.X, .X): return [(.X, .identity)]
            default: return []
            }
        }
        
        let Δ: Coproduct<R> = { e in
            switch e {
            case .I: return [(.I, .I, -.identity)]
            default: return []
            }
        }
        
        return d(μ, Δ)
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

