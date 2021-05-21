//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

import SwiftyMath
import SwiftyHomology

public protocol Cube {
    associatedtype Vertex
    associatedtype Edge
    typealias Coords = BitSequence
    
    var dim: Int { get }
    subscript(v: Coords) -> Vertex { get }
    func edge(from: Coords, to: Coords) -> Edge
}

extension Cube {
    var startVertex: Vertex {
        self[ Coords.zeros(length: dim) ]
    }
    
    var endVertex: Vertex {
        self[ Coords.ones(length: dim) ]
    }
    
    func edges(from v: Coords) -> [Edge] {
        v.successors.map { w in
            edge(from: v, to: w)
        }
    }
}

public protocol ModuleCube: Cube where Vertex == ModuleStructure<BaseModule>, Edge == ModuleEnd<BaseModule> {
    associatedtype BaseModule: Module
    typealias R = BaseModule.BaseRing
    typealias M = IndexedModule<Coords, BaseModule>
}

extension ModuleCube {
    func edgeSign(from v: Coords, to w: Coords) -> R {
        assert(v.length == dim)
        assert(w.length == dim)
        
        guard let i = (0 ..< dim).first(where: { j in v[j] != w[j] }) else {
            fatalError("invalid states: \(v), \(w)")
        }
        let e = (0 ... i).count{ j in v[j] == 1 }
        return e.isEven ? .identity : -.identity
    }
    
    public func differential(_ i: Int) -> ModuleEnd<M> {
        ModuleEnd { (z: M) in
            z.elements.sum { (v, x) in
                v.successors.sum { w in
                    let e = edgeSign(from: v, to: w)
                    let f = edge(from: v, to: w)
                    let y = e * f(x)
                    return M(index: w, value: y)
                }
            }
        }
    }
    
    public func asChainComplex() -> ChainComplex1<M> {
        ChainComplex1(
            grid: { i in
                let n = self.dim
                guard (0 ... n).contains(i) else {
                    return .zeroModule
                }
                
                let vs = Coords.sequences(length: dim, weight: i)
                let modules = Dictionary(keys: vs) { self[$0] }
                return ModuleStructure.formDirectSum(modules)
            },
            degree: 1,
            differential: { i in self.differential(i) }
        )
    }
}
