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
    public func star(_ v: Vertex) -> SimplicialComplex {
        return star( Simplex(v) )
    }
    
    public func star(_ s: Simplex) -> SimplicialComplex {
        return SimplicialComplex( maximalCells: maximalCells.filter{ $0.contains(s) } ).named("St\(s)")
    }
    
    public func link(_ v: Vertex) -> SimplicialComplex {
        return (star(v) - v).named("Lk\(v)")
    }
    
    public func link(_ s: Simplex) -> SimplicialComplex {
        return (star(s) - s).named("Lk\(s)")
    }
    
    public var boundaryVertices: [Vertex] {
        return vertices.filter { v in
            self.link(v).orientationCycle == nil
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
    
    public static func ×(K1: SimplicialComplex, v2: Vertex) -> SimplicialComplex {
        let K2 = SimplicialComplex(maximalCells: Simplex([v2])).named(v2.label)
        return K1 × K2
    }
    
    public static func ×(v1: Vertex, K2: SimplicialComplex) -> SimplicialComplex {
        let K1 = SimplicialComplex(maximalCells: Simplex([v1])).named(v1.label)
        return K1 × K2
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
    
    public func pow(_ n: Int) -> SimplicialComplex {
        let cells = maximalCells
        let pcells = (1 ..< n).reduce(cells) { (pow, _) -> [Simplex] in
            SimplicialComplex.productSimplices(pow, cells)
        }
        return SimplicialComplex(name: "\(name)^\(n)", maximalCells: pcells)
    }
    
    public static func /(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
        let vs = Set(K2.vertices)
        let v0 = vs.anyElement!
        let map = SimplicialMap(from: K1) { v in vs.contains(v) ? v0 : v }
        return map.image.named("\(K1.name) / \(K2.name)")
    }
    
    public static func ∨(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
        let (v1, v2) = (K1.vertices[0], K2.vertices[0])
        let K = K1 + K2
        let map = SimplicialMap(from: K, [v2 : v1])
        return map.image.named("\(K1.name) ∨ \(K2.name)")
    }
    
    public static func ∧(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
        let (v1, v2) = (K1.vertices[0], K2.vertices[0])
        return (K1 × K2) / ( (K1 × v2) ∨ (v1 × K2) )
    }
    
    public func cone(intervalVertices n: Int = 2) -> SimplicialComplex {
        let K = self
        let I = SimplicialComplex.interval(vertices: n)
        return ( (K × I) / (K × I.vertices[0]) ).named("C(\(K.name))")
    }
    
    public func suspension(intervalVertices n: Int = 3) -> SimplicialComplex {
        let K = self
        let I = SimplicialComplex.interval(vertices: n)
        return ( (K × I) / (K × I.vertices[0]) / (K × I.vertices[n - 1]) ).named("S(\(K.name))")
    }
    
    public func connectedSum(with K2: SimplicialComplex) -> SimplicialComplex {
        let K1 = self
        assert(K1.dim == K2.dim)
        let (s1, s2) = (K1.cells(ofDim: K1.dim).anyElement!, K2.cells(ofDim: K1.dim).anyElement!)
        return ((K1 + K2) - s1 - s2).identifyVertices(s1.vertices.enumerated().map{ (i, v) in (v, s2.vertices[i])})
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
    
    public var dualComplex: CellularComplex {
        let K = self
        let n = K.dim
        let (SdK, s2b, b2s) = K._barycentricSubdivision()
        
        var cellsList = [[CellularCell]]()
        var s2d = [Simplex : CellularCell]()
        var d2s = [CellularCell : Simplex]()
        
        for i in (0 ... n).reversed() {
            let bcells = SdK.cells(ofDim: n - i)
            let dcells = K.cells(ofDim: i).map { s -> CellularCell in
                let chain: SimplicialChain<IntegerNumber> = {
                    let b = s2b[s]!
                    let star = SimplicialComplex( maximalCells: bcells.filter{ (bcell) in
                        bcell.contains(b) && bcell.vertices.forAll{ b2s[$0]!.contains(s) }
                    })
                    let link = star - b
                    let H = Homology(star, link, IntegerNumber.self)
                    return H[H.topDegree].generators[0]
                }()
                
                let z = chain.boundary()
                let boundary = CellularChain( K.cofaces(ofCell: s).map{ t -> (CellularCell, IntegerNumber) in
                    let dcell = s2d[t]!
                    
                    let t0 = dcell.simplices.basis[0] // take any simplex to detect orientation
                    let e = (dcell.simplices[t0] == z[t0]) ? 1 : -1
                    
                    return (dcell, e)
                })
                
                let d = CellularCell(chain, boundary)
                s2d[s] = d
                d2s[d] = s
                
                return d
            }
            cellsList.append(dcells)
        }
        
        return CellularComplex(SdK, cellsList)
    }
}

public extension Vertex {
    public func join(_ K: SimplicialComplex) -> SimplicialComplex {
        let cells = K.maximalCells.map{ s in self.join(s) }
        return SimplicialComplex(name: "\(self) * \(K.name)", maximalCells: cells)
    }
}
