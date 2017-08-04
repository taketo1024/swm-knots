//
//  BarycentricSubdivision.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct BarycentricSubdivision: GeometricComplex {
    public typealias Cell = Simplex
    
    public let vertexSet: VertexSet
    internal let cells: [[Simplex]]
    
    private var b2s: [Vertex: Simplex] = [:]
    private var s2b: [Simplex: Vertex] = [:]
    
    private init(_ vertexSet: VertexSet, _ cells: [[Simplex]], _ b2s: [Vertex: Simplex], _ s2b: [Simplex: Vertex]) {
        self.vertexSet = vertexSet
        self.cells = cells
        self.b2s = b2s
        self.s2b = s2b
    }
    
    public init(_ K: SimplicialComplex) {
        var V = VertexSet()
        var bcells = Set<Simplex>()
        
        var b2s: [Vertex: Simplex] = [:]
        var s2b: [Simplex: Vertex] = [:]
        
        func generate(cells: [Simplex], barycenters: [Vertex]) {
            let s = cells.last!
            let v = s2b[s] ?? {
                let label = (s.dim > 0) ? "b\(s.vertices.map{String($0.index)}.joined())" : s.vertices.first!.label
                let v = V.add(label: label)
                b2s[v] = s
                s2b[s] = v
                return v
                }()
            
            if s.dim > 0 {
                for t in s.faces() {
                    generate(cells: cells + [t], barycenters: barycenters + [v])
                }
            } else {
                let bcell = Simplex(barycenters + [v])
                bcells.insert(bcell)
            }
        }
        
        for s in K.maximalCells {
            generate(cells: [s], barycenters: [])
        }
        
        self.init(V, SimplicialComplex.generateCells(bcells), b2s, s2b)
    }
    
    public func barycenterOf(_ s: Simplex) -> Vertex? {
        return s2b[s]
    }
    
    public func simplex(forBarycenter v: Vertex) -> Simplex? {
        return b2s[v]
    }
    
    public var dim: Int {
        return cells.count - 1
    }
    
    public func skeleton(_ dim: Int) -> BarycentricSubdivision {
        let sub = Array(cells[0 ... dim])
        return BarycentricSubdivision(
            vertexSet, sub,
            b2s.filterElements{ (_, s) in s.dim <= dim},
            s2b.filterElements{ (s, _) in s.dim <= dim}
        )
    }
    
    public func allCells(ofDim i: Int) -> [Simplex] {
        return (0...dim).contains(i) ? cells[i] : []
    }
    
    public func boundary<R: Ring>(ofCell s: Simplex) -> FreeModule<R, Simplex> {
        return s.boundary()
    }
    
    public func asSimplicialComplex() -> SimplicialComplex {
        return SimplicialComplex(vertexSet, cells)
    }
}

public extension SimplicialComplex {
    public func barycentricSubdivision() -> BarycentricSubdivision {
        return BarycentricSubdivision(self)
    }
}
