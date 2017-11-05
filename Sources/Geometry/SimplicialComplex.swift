//
//  SimplicialComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/17.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct SimplicialComplex: GeometricComplex {
    public typealias Cell = Simplex
    
    public var name: String
    internal let cellTable: [[Simplex]]
    
    // root initializer
    internal init(name: String? = nil, _ cellTable: [[Simplex]]) {
        self.name = name ?? "_"
        self.cellTable = cellTable
    }
    
    public init<S: Sequence>(name: String? = nil, allCells cells: S) where S.Iterator.Element == Simplex {
        self.init(name: name, SimplicialComplex.alignCells(cells, generateFaces: false))
    }
    
    public init(name: String? = nil, allCells cells: Simplex...) {
        self.init(name: name, allCells: cells)
    }
    
    public init<S: Sequence>(name: String? = nil, maximalCells cells: S) where S.Iterator.Element == Simplex {
        self.init(name: name, SimplicialComplex.alignCells(cells, generateFaces: true))
    }
    
    public init(name: String? = nil, maximalCells cells: Simplex...) {
        self.init(name: name, maximalCells: cells)
    }
    
    public var dim: Int {
        return cellTable.count - 1
    }
    
    public func skeleton(_ dim: Int) -> SimplicialComplex {
        let sub = Array(cellTable[0 ... dim])
        return SimplicialComplex(name: "\(self.name)_(\(dim))", sub)
    }
    
    public func cells(ofDim i: Int) -> [Simplex] {
        return (0...dim).contains(i) ? cellTable[i] : []
    }
    
    public var allVertices: [Vertex] {
        return cells(ofDim: 0).map{ $0.vertices[0] }
    }
    
    private var _maximalCells: Cache<[Simplex]> = Cache()
    
    public var maximalCells: [Simplex] {
        if let cells = _maximalCells.value {
            return cells
        }
        
        var cells = Array(self.cellTable.reversed().joined())
        var i = 0
        while i < cells.count {
            let s = cells[i]
            let subs = s.allSubsimplices().dropFirst()
            for t in subs {
                if let j = cells.index(of: t) {
                    cells.remove(at: j)
                }
            }
            i += 1
        }
        
        _maximalCells.value = cells
        return cells
    }
    
    public func boundary<R: Ring>(ofCell s: Simplex) -> FreeModule<Simplex, R> {
        return s.boundary()
    }
    
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
    
    public func cofaces(ofCell s: Simplex) -> [Simplex] {
        return cells(ofDim: s.dim + 1).filter{ $0.contains(s) }
    }
    
    internal static func alignCells<S: Sequence>(_ cells: S, generateFaces gFlag: Bool) -> [[Simplex]] where S.Iterator.Element == Simplex {
        let dim = cells.reduce(0) { max($0, $1.dim) }
        let set = gFlag ? cells.reduce( Set<Simplex>() ){ (set, cell) in set.union( cell.allSubsimplices() ) }
                        : Set(cells)
        
        var cells: [[Simplex]] = (0 ... dim).map{_ in []}
        for s in set {
            cells[s.dim].append(s)
        }
        
        return cells.map { list in list.sorted() }
    }
}

// Operations
public extension SimplicialComplex {
    // disjoint union
    public static func +(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
        let dim = max(K1.dim, K2.dim)
        let cells = (0 ... dim).map{ i in K1.cells(ofDim: i) + K2.cells(ofDim: i) }
        return SimplicialComplex(name: "\(K1) + \(K2)", cells)
    }
    
    // subtraction (the result may not be a proper simplicial complex)
    public static func -(K1: SimplicialComplex, v: Vertex) -> SimplicialComplex {
        let K2 = SimplicialComplex(name: v.label, allCells: Simplex([v]))
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
        let simplexPairs = K1.maximalCells.allCombinations(with: K2.maximalCells)
        let vertexPairs  = simplexPairs.flatMap{ (s, t) -> [[(Vertex, Vertex)]] in
            let k = s.dim + t.dim
            
            // list of indices with each (k + 1)-elements in increasing order
            let Is: [[Int]] = (s.dim + 1).multichoose(k + 1)
            let Js: [[Int]] = (t.dim + 1).multichoose(k + 1)
            
            // list of pairs of ordered indices [(I, J), ...]
            let allPairs: [([Int], [Int])]  = Is.allCombinations(with: Js)
            
            // filter valid pairs that form a k-simplex
            // if (I[i], J[i]) == (I[i + 1], J[i + 1]), then these two vertices collapse.
            let validPairs = allPairs.filter{ (I, J) in
                (0 ..< k).forAll{ (i: Int) -> Bool in (I[i], J[i]) != (I[i + 1], J[i + 1]) }
            }
            
            // indexPairs that correspond to the indices of each VertexSets
            return validPairs.map{ (I, J) -> [(Vertex, Vertex)] in
                zip(I, J).map{ (i, j) in (s.vertices[i], t.vertices[j]) }
            }
        }
        
        let cells = vertexPairs.map { (list: [(Vertex, Vertex)]) -> Simplex in
            let vertices = list.map{ (v, w) in v × w }
            return Simplex(vertices)
        }
        
        return SimplicialComplex(name: "\(K1.name) × \(K2.name)", maximalCells: cells)
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

// Commonly used examples
public extension SimplicialComplex {
    static func point() -> SimplicialComplex {
        let v = Vertex("pt")
        return SimplicialComplex(name: "pt", allCells: Simplex([v]))
    }
    
    static func interval() -> SimplicialComplex {
        let V = Vertex.generate(2)
        let s = Simplex(V, indices: [0, 1])
        return SimplicialComplex(name: "I", maximalCells: [s])
    }
    
    static func circle() -> SimplicialComplex {
        return SimplicialComplex.sphere(dim: 1)
    }
    
    static func sphere(dim: Int) -> SimplicialComplex {
        let V = Vertex.generate(dim + 2)
        let s = Simplex(V, indices: 0 ... (dim + 1))
        return SimplicialComplex(name: "S^\(dim)", maximalCells: s.faces())
    }
    
    static func ball(dim: Int) -> SimplicialComplex {
        let V = Vertex.generate(dim + 1)
        let s = Simplex(V, indices: 0...dim)
        return SimplicialComplex(name: "D^\(dim)", maximalCells: [s])
    }
    
    static func torus(dim: Int) -> SimplicialComplex {
        let S = SimplicialComplex.circle()
        var T = (1 ..< dim).reduce(S) { (K, _) in K × S }
        T.name = "T^\(dim)"
        return T
    }
    
    // ref: Minimal Triangulations of Manifolds https://arxiv.org/pdf/math/0701735.pdf
    static func realProjectiveSpace(dim: Int) -> SimplicialComplex {
        switch dim {
        case 1:
            return circle()
        case 2:
            let V = Vertex.generate(6)
            let indices = [(0,1,3),(1,4,3),(1,2,4),(4,2,0),(4,0,5),(0,1,5),(1,2,5),(2,3,5),(0,3,2),(3,4,5)]
            let simplices = indices.map { v in Simplex(V, indices: [v.0, v.1, v.2]) }
            return SimplicialComplex(name: "RP^2", maximalCells: simplices)
        case 3:
            let V = Vertex.generate(11)
            let indices = [(1,2,3,7), (1,2,3,0), (1,2,6,9), (1,2,6,0), (1,2,7,9), (1,3,5,10), (1,3,5,0), (1,3,7,10), (1,4,7,9), (1,4,7,10), (1,4,8,9), (1,4,8,10), (1,5,6,8), (1,5,6,0), (1,5,8,10), (1,6,8,9), (2,3,4,8), (2,3,4,0), (2,3,7,8), (2,4,6,10), (2,4,6,0), (2,4,8,10), (2,5,7,8), (2,5,7,9), (2,5,8,10), (2,5,9,10), (2,6,9,10), (3,4,5,9), (3,4,5,0), (3,4,8,9), (3,5,9,10), (3,6,7,8), (3,6,7,10), (3,6,8,9), (3,6,9,10), (4,5,6,7), (4,5,6,0), (4,5,7,9), (4,6,7,10), (5,6,7,8)]
            let simplices = indices.map { v in Simplex(V, indices: [v.0, v.1, v.2, v.3]) }
            return SimplicialComplex(name: "RP^3", maximalCells: simplices)
        default:
            fatalError("RP^n (n >= 4) not yet supported.")
        }
    }
}

// Topological Invariants
public extension SimplicialComplex {
    // TODO remove
    public func preferredOrientation() -> SimplicialChain<IntegerNumber>? {
        return preferredOrientation(type: IntegerNumber.self)
    }
    
    public func preferredOrientation<R: EuclideanRing>(type: R.Type) -> SimplicialChain<R>? {
        let H = HomologyGroupInfo<Descending, Simplex, R>(
            degree: dim,
            basis: cells(ofDim: dim),
            matrix1: boundaryMatrix(dim),
            matrix2: boundaryMatrix(dim + 1)
        )
        
        if H.rank == 1 {
            return H.summands[0].generator
        } else {
            return nil
        }
    }
    // --TODO
    
    public var eulerNumber: Int {
        return (0 ... dim).sum{ i in (-1).pow(i) * cells(ofDim: i).count }
    }

    public var fundamentalClass: SimplicialChain<IntegerNumber>? {
        return fundamentalClass(type: IntegerNumber.self)
    }
    
    public func fundamentalClass<R: EuclideanRing>(type: R.Type) -> SimplicialChain<R>? {
        let H = Homology(self, R.self)
        let s = H[dim].summands
        
        if let first = s.first, s.count == 1 && first.isFree {
            return first.generator
        } else {
            return nil
        }
    }
    
    public var eulerClass: SimplicialCochain<IntegerNumber>? {
        return eulerClass(IntegerNumber.self)
    }
    
    public func eulerClass<R: EuclideanRing>(_ type: R.Type) -> SimplicialCochain<R>? {
        
        // See [Milnor-Stasheff: Characteristic Classes §11]
        
        let M = self
        let d = SimplicialMap.diagonal(from: M)
        
        let MxM = M × M
        let ΔM = d.image
        
        let H = Cohomology(MxM, MxM - ΔM, R.self)
        let s = H[dim].summands
        
        if let first = s.first, s.count == 1 && first.isFree {
            let u = first.generator                      // the Diagonal cohomology class of M
            let e = d.asCochainMap(R.self).appliedTo(u)  // the Euler class of M
            return e
        } else {
            return nil
        }
    }
}
