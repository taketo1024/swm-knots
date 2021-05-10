//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/10.
//

import SwiftyMath
import SwiftyHomology

internal struct KRTotalCube<R: Ring>: ModuleCube {
    typealias BaseModule = KR.HorizontalModule<R>
    typealias Vertex = ModuleObject<BaseModule>
    typealias Edge = ModuleEnd<BaseModule>

    let L: Link
    let connection: [Int : KR.EdgeConnection<R>]
    let vertex: (Coords) -> Vertex
    
    init(link L: Link, connection: [Int : KR.EdgeConnection<R>], vertex: @escaping (Coords) -> Vertex) {
        self.L = L
        self.connection = connection
        self.vertex = vertex
    }
    
    var dim: Int {
        L.crossingNumber
    }
    
    subscript(v: Coords) -> ModuleObject<BaseModule> {
        vertex(v)
    }
    
    private func edgeFactor(from: Coords, to: Coords, subcoords: Coords) -> KR.EdgeRing<R> {
        if !(from < to) {
            return .zero
        }
        let e = (to - from).enumerated().filter{ (_, b) in b == 1 }
        if e.count > 1 {
            return .zero
        }
        
        let p = e.first!.offset
        let il = connection[p]!.il
        
        switch (L.crossings[p].crossingSign, subcoords[p]) {
        case (+1, 0), (-1, 1):
            return il
        case (+1, 1), (-1, 0):
            return .identity
        default:
            fatalError("impossible")
        }
    }
    
    func edge(from: Coords, to: Coords) -> ModuleEnd<BaseModule> {
        return ModuleEnd { x -> BaseModule in
            x.elements.sum { (subcoords, z) -> BaseModule in
                let e = edgeFactor(from: from, to: to, subcoords: subcoords)
                let p = (MultivariatePolynomial(z) * e).asLinearCombination
                return IndexedModule(index: subcoords, value: p)
            }
        }
    }
}
