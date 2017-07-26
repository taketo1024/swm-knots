//
//  BarycentricSubdivision.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public final class BarycentricSubdivision: SimplicialComplex {
    private var bcenter2simplex: [Vertex : Simplex] = [:]
    private var simplex2bcenter: [Simplex: Vertex ] = [:]
    
    public convenience init(_ K: SimplicialComplex) {
        var V = VertexSet()
        var S = Set<Simplex>()
        
        var bcenter2simplex: [Vertex : Simplex] = [:]
        var simplex2bcenter: [Simplex: Vertex ] = [:]
        
        func generate(cells: [Simplex], barycenters: [Vertex]) {
            let s = cells.last!
            let v = simplex2bcenter[s] ?? {
                let label = (s.dim > 0) ? "b\(s.vertices.map{String($0.index)}.joined())" : s.vertices.first!.label
                let v = V.add(label: label)
                bcenter2simplex[v] = s
                simplex2bcenter[s] = v
                return v
                }()
            
            if s.dim > 0 {
                for t in s.faces() {
                    generate(cells: cells + [t], barycenters: barycenters + [v])
                }
            } else {
                let bs = Simplex(barycenters + [v])
                S.insert(bs)
            }
        }
        
        for s in K.maximalCells {
            generate(cells: [s], barycenters: [])
        }
        
        self.init(V, S, generate: true)
    }
    
    public func barycenterOf(_ s: Simplex) -> Vertex? {
        return simplex2bcenter[s]
    }
    
    public func simplex(forBarycenter v: Vertex) -> Simplex? {
        return bcenter2simplex[v]
    }
}

public extension SimplicialComplex {
    public func barycentricSubdivision() -> BarycentricSubdivision {
        return BarycentricSubdivision(self)
    }
}
