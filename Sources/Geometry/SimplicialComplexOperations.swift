//
//  SimplicialComplexOperations.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/06.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// Operations
public extension SimplicialComplex {
    public func star(_ v: Vertex) -> [Simplex] { // returns only maximal cells
        return maximalCells.filter{ $0.contains(v) }
    }
    
    public func star(_ s: Simplex) -> [Simplex] { // returns only maximal cells
        return maximalCells.filter{ $0.contains(s) }
    }
    
    public func link(_ v: Vertex) -> [Simplex] { // returns only maximal cells
        return star(v).map{ $0.subtract(v) }.filter{ $0.dim >= 0 }
    }
    
    public func link(_ s: Simplex) -> [Simplex] { // returns only maximal cells
        return star(s).map{ $0.subtract(s) }.filter{ $0.dim >= 0 }
    }
    
    public var boundaryVertices: [Vertex] {
        return vertices.filter { v in
            SimplicialComplex(maximalCells: self.link(v)).orientationCycle == nil
        }
    }
    
    public func identifyVertices(_ pairs: [(Vertex, Vertex)]) -> SimplicialComplex {
        let dict = Dictionary(pairs: pairs)
        let map = SimplicialMap(from: self) { v in dict[v] ?? v }
        return map.image
    }
    
    // disjoint union
    public static func +(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
        let dim = max(K1.dim, K2.dim)
        let cells = (0 ... dim).map{ i in (K1.cells(ofDim: i) + K2.cells(ofDim: i)).unique() }
        return SimplicialComplex(name: "\(K1) + \(K2)", cells)
    }
    
    // subtraction (the result may not be a proper simplicial complex)
    public static func -(K1: SimplicialComplex, v: Vertex) -> SimplicialComplex {
        return K1 - Simplex(v)
    }
    
    public static func -(K1: SimplicialComplex, s: Simplex) -> SimplicialComplex {
        let K2 = SimplicialComplex(name: s.description, allCells: [s])
        return K1 - K2
    }
    
    public static func -(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
        let subtr = K2.allCells
        let cells = K1.cellTable.map{ list -> [Simplex] in
            return list.filter{ s in subtr.forAll{ !s.contains($0) } }
        }
        return SimplicialComplex(name: "\(K1) - \(K2)", cells)
    }
    
    // product complex
    public static func ×(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
        let pcells = productSimplices(K1.maximalCells, K2.maximalCells)
        return SimplicialComplex(name: "\(K1.name) × \(K2.name)", maximalCells: pcells)
    }
    
    public func pow(_ n: Int) -> SimplicialComplex {
        let cells = maximalCells
        let pcells = (1 ..< n).reduce(cells) { (pow, _) -> [Simplex] in
            SimplicialComplex.productSimplices(pow, cells)
        }
        return SimplicialComplex(name: "\(name)^\(n)", maximalCells: pcells)
    }
    
    internal static func productSimplices(_ ss: [Simplex], _ ts: [Simplex]) -> [Simplex] {
        return ss.allCombinations(with: ts).flatMap{ (s, t) in productSimplices(s, t) }
    }
    
    internal static func productSimplices(_ s: Simplex, _ t: Simplex) -> [Simplex] {
        let (n, m) = (s.dim, t.dim)
        
        // generate array of (n + m)-dim product simplices by the zig-zag method.
        
        let combis = (n + m).choose(n)
        let vPairs = combis.map{ c -> [(Vertex, Vertex)] in
            let start = [(s.vertices[0], t.vertices[0])]
            var (i, j) = (0, 0)
            
            return start + (0 ..< (n + m)).map { k -> (Vertex, Vertex) in
                if c.contains(k) {
                    defer { i += 1 }
                } else {
                    defer { j += 1 }
                }
                return (s.vertices[i], t.vertices[j])
            }
        }
        
        return vPairs.map { list -> Simplex in
            let vertices = list.map { (v, w) in v × w }
            return Simplex(vertices)
        }
    }
    
    public func connectedSum(with K2: SimplicialComplex) -> SimplicialComplex {
        assert(self.dim == K2.dim)
        let (s1, s2) = (self.cells(ofDim: self.dim).anyElement!, K2.cells(ofDim: self.dim).anyElement!)
        return ((self + K2) - s1 - s2).identifyVertices(s1.vertices.enumerated().map{ (i, v) in (v, s2.vertices[i])})
    }
    
    public var barycentricSubdivision: SimplicialComplex {
        return _barycentricSubdivision().0
    }
    
    internal func _barycentricSubdivision() -> (SimplicialComplex, s2b: [Simplex: Vertex], b2s: [Vertex: Simplex]) {
        var bcells = Set<Simplex>()
        
        var b2s: [Vertex: Simplex] = [:]
        var s2b: [Simplex: Vertex] = [:]
        
        func generate(cells: [Simplex], barycenters: [Vertex]) {
            let s = cells.last!
            let v = s2b[s] ?? {
                let v = (s.dim > 0) ? Vertex(prefix: "b") : s.vertices.first!
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
        
        for s in self.maximalCells {
            generate(cells: [s], barycenters: [])
        }
        
        return (SimplicialComplex(name: "Sd(\(name))", maximalCells: bcells), s2b, b2s)
    }
}

public extension Vertex {
    public func join(_ K: SimplicialComplex) -> SimplicialComplex {
        let cells = K.maximalCells.map{ s in self.join(s) }
        return SimplicialComplex(name: "\(self) * \(K.name)", maximalCells: cells)
    }
}
