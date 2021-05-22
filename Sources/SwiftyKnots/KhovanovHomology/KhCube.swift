//
//  ModuleCube.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/06/06.
//

import SwiftyMath
import SwiftyHomology

// An n-dim cube with Modules on all vertices I ∈ {0, 1}^n .

public struct KhovanovCube<R: Ring>: ModuleCube {
    public typealias BaseModule = LinearCombination<R, MultiTensorGenerator<KhovanovAlgebraGenerator>>
    public typealias Vertex = ModuleStructure<BaseModule>
    public typealias Edge = ModuleEnd<BaseModule>
    
    public let type: KhovanovAlgebra<R>
    public let link: Link
    
    public init(type: KhovanovAlgebra<R>, link L: Link) {
        self.type = type
        self.link = L
    }
    
    public var dim: Int {
        link.crossingNumber
    }
    
    public subscript(v: Coords) -> ModuleStructure<BaseModule> {
        vertexInfo(v).module
    }
    
    private func vertexInfo(_ s: Coords) -> VertexInfo {
        assert(s.length == dim)
        return VertexInfo(link, s)
    }
    
    public var maxQdegree: Int {
        let v1 = Coords.ones(length: dim)
        return vertexInfo(v1).maxQdegree
    }
    
    public var minQdegree: Int {
        let v0 = Coords.zeros(length: dim)
        return vertexInfo(v0).minQdegree
    }

    public enum EdgeDescription {
        case merge(from: (Int, Int), to: Int)
        case split(from: Int, to: (Int, Int))
    }
    
    public func edgeDescription(from s0: Coords, to s1: Coords) -> EdgeDescription {
        let (v0, v1) = (vertexInfo(s0), vertexInfo(s1))
        let (c1, c2) = (v0.circles, v1.circles)
        let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
        
        switch (d1.count, d2.count) {
        case (2, 1):
            let (i1, i2) = (c1.firstIndex(of: d1[0])!, c1.firstIndex(of: d1[1])!)
            let j = c2.firstIndex(of: d2[0])!
            return .merge(from: (i1, i2), to: j)
            
        case (1, 2):
            let i = c1.firstIndex(of: d1[0])!
            let (j1, j2) = (c2.firstIndex(of: d2[0])!, c2.firstIndex(of: d2[1])!)
            return .split(from: i, to: (j1, j2))
            
        default:
            fatalError()
        }
    }
    
    public func edge(from s0: Coords, to s1: Coords) -> ModuleEnd<BaseModule> {
        switch self.edgeDescription(from: s0, to: s1) {
        case let .merge(from: (i1, i2), to: j):
            return MultiTensorHom(from: type.product, inputIndices: (i1, i2), outputIndex: j)
        case let .split(from: i, to: (j1, j2)):
            return MultiTensorHom(from: type.coproduct, inputIndex: i, outputIndices: (j1, j2))
        }
    }
    
    fileprivate struct VertexInfo {
        let coords: Coords
        let circles: [Link.Component]
        let module: ModuleStructure<BaseModule>
        
        init(_ L: Link, _ v: Coords) {
            let circles = L.resolved(by: v).components
            
            let r = circles.count
            let (I, X) = (KhovanovAlgebraGenerator.I, KhovanovAlgebraGenerator.X)
            let generators = BitSequence.allSequences(length: r).map { b in
                MultiTensorGenerator( b.map { $0 == 0 ? I : X } )
            }
            
            self.coords = v
            self.circles = circles
            self.module = ModuleStructure(rawGenerators: generators)
        }
        
        private func qDegree(_ x: MultiTensorGenerator<KhovanovAlgebraGenerator>) -> Int {
            coords.weight + x.degree + circles.count
        }
        
        var maxQdegree: Int {
            module.generators.map{ qDegree($0.asGenerator!) }.max() ?? 0
        }
        
        var minQdegree: Int {
            module.generators.map{ qDegree($0.asGenerator!) }.min() ?? 0
        }
    }
}
