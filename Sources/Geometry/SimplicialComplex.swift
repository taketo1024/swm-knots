//
//  SimplicialComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/17.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct SimplicialComplex: GeometricComplex {
    public let dim: Int
    public let vertexSet: VertexSet
    internal let simplicesList: [[Simplex]]
    
    // root initializer
    public init(_ vertexSet: VertexSet, _ simplices: [[Simplex]]) {
        self.dim = simplices.count - 1
        self.vertexSet = vertexSet
        self.simplicesList = simplices
    }
    
    public init<S: Sequence>(_ vertexSet: VertexSet, _ simplices: S, generate: Bool = false) where S.Iterator.Element == Simplex {
        let simplices = { () -> [[Simplex]] in
            let dim = simplices.reduce(0) { max($0, $1.dim) }
            let set = generate ? simplices.reduce(Set<Simplex>()){$0.union($1.allSubsimplices()) } : Set(simplices)
            
            var simplices: [[Simplex]] = (0 ... dim).map{_ in []}
            for s in set {
                simplices[s.dim].append(s)
            }
            return simplices
        }()
        self.init(vertexSet, simplices)
    }
    
    public func skeleton(_ dim: Int) -> SimplicialComplex {
        let sub = Array(simplicesList[0 ... dim])
        return SimplicialComplex(vertexSet, sub)
    }
    
    public func simplices(_ i: Int) -> [Simplex] {
        return (0...dim).contains(i) ? simplicesList[i] : []
    }
    
    public func boundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<Simplex, R> {
        let from = simplices(i)
        let to = (i > 0) ? simplices(i - 1) : []
        let matrix: DynamicMatrix<R> = boundaryMapMatrix(from, to)
        return FreeModuleHom<Simplex, R>(domainBasis: from, codomainBasis: to, matrix: matrix)
    }

    public func coboundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<Simplex, R> {
        // Regard the basis of C_i as the dual basis of C^i.
        // Since <δf, c> = <f, ∂c>, the matrix is given by the transpose.
        
        let from = simplices(i)
        let to = (i < dim) ? simplices(i + 1) : []
        let matrix: DynamicMatrix<R> = boundaryMapMatrix(to, from).transposed
        return FreeModuleHom<Simplex, R>(domainBasis: from, codomainBasis: to, matrix: matrix)
    }
    
    private func boundaryMapMatrix<R: Ring>(_ from: [Simplex], _ to : [Simplex]) -> DynamicMatrix<R> {
        var matrix = DynamicMatrix(rows: to.count, cols: from.count) { _ in R.zero }
        let toIndex = Dictionary(to.enumerated().map{($1, $0)})
        
        from.enumerated().forEach { (j, s) in
            s.faces().enumerated().forEach { (k, t) in
                let i = toIndex[t]!
                matrix[i, j] = R(k.evenOddSign)
            }
        }
        
        return matrix
    }
}

public extension SimplicialComplex {
    static func point() -> SimplicialComplex {
        return SimplicialComplex.ball(dim: 0)
    }
    
    static func interval() -> SimplicialComplex {
        return SimplicialComplex.ball(dim: 1)
    }
    
    static func circle() -> SimplicialComplex {
        return SimplicialComplex.sphere(dim: 1)
    }
    
    static func ball(dim: Int) -> SimplicialComplex {
        let V = VertexSet(number: dim + 1)
        let s = V.simplex(indices: Array(0...dim))
        return SimplicialComplex(V, [s], generate: true)
    }
    
    static func sphere(dim: Int) -> SimplicialComplex {
        return ball(dim: dim + 1).skeleton(dim)
    }
    
    static func torus(dim: Int) -> SimplicialComplex {
        return (1 ..< dim).reduce(SimplicialComplex.circle()) { (r, _) in r * SimplicialComplex.circle() }
    }
}

// disjoint union
public func +(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
    let (n1, n2) = (K1.vertexSet.vertices.count, K2.vertexSet.vertices.count)
    let V = VertexSet(number: n1 + n2)
    let dim = max(K1.dim, K2.dim)
    
    let simplices = (0 ... dim).map{ i in
        K1.simplices(i).map{ s in V.simplex(indices: s.vertices.map{$0.index}) } +
            K2.simplices(i).map{ s in V.simplex(indices: s.vertices.map{$0.index + n1}) }
    }
    return SimplicialComplex(V, simplices)
}

// product complex
public func *(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
    let (n1, n2) = (K1.vertexSet.vertices.count, K2.vertexSet.vertices.count)
    let V = VertexSet(number: n1 * n2)
    
    // discard simplices that are faces of others.
    func distinctSimplices(_ K: SimplicialComplex) -> Set<Simplex> {
        let set = Set(K.simplicesList.joined())
        return Set( set.filter{ s in set.forAll{ t in t == s || !t.contains(s) } } )
    }
    
    let (S1, S2) = (distinctSimplices(K1), distinctSimplices(K2))
    let simplexPairs: [(Simplex, Simplex)] = S1.flatMap{ s in S2.map{ t in (s, t) } }
    
    let indexPairs: [[(Int, Int)]] = simplexPairs.flatMap{(s, t) -> [[(Int, Int)]] in
        (0 ... s.dim + t.dim).flatMap{ k -> [[(Int, Int)]] in
            // list of ordered indices [(i0 <= i1 <= ... <= ik), ... ]
            let Is: [[Int]] = (s.dim + 1).multichoose(k + 1)
            let Js: [[Int]]  = (t.dim + 1).multichoose(k + 1)
            
            // list of pairs of ordered indices [(I, J), ...]
            let allPairs: [([Int], [Int])]  = Is.flatMap{ I in Js.map{ J in (I, J) } }
            
            // filter valid pairs that form a k-simplex
            let validPairs = allPairs.filter{ (I, J) in
                (0 ..< k).forAll{ (i: Int) -> Bool in
                    (I[i] != I[i + 1]) || (J[i] != J[i + 1])
                }
            }
            
            // indexPairs that correspond to the indices of each VertexSets
            return validPairs.map{ (I, J) -> [(Int, Int)] in
                zip(I, J).map{ (i, j) in (s.vertices[i].index, t.vertices[j].index) }
            }
        }
    }
    
    let simplices = indexPairs.map { (list: [(Int, Int)]) -> Simplex in
        let indices = list.map{ (i, j) in i * n2 + j }
        return V.simplex(indices: indices)
    }.unique()
    
    return SimplicialComplex(V, simplices)
}
