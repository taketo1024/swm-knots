//
//  SimplicialComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/17.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct SimplicialComplex {
    public let vertexSet: VertexSet
    public let simplices: OrderedSet<Simplex>
    
    public init<S: Sequence>(_ vertexSet: VertexSet, _ simplices: S, generate: Bool = false) where S.Iterator.Element == Simplex {
        self.vertexSet = vertexSet
        self.simplices = generate ?
            simplices.reduce(OrderedSet()) { $0 + $1.allSubsimplices() }
            : OrderedSet(simplices)
    }
    
    public var dim: Int {
        return simplices.reduce(0) { max($0, $1.dim) }
    }
    
    public func skeleton(_ dim: Int) -> SimplicialComplex {
        let sub = simplices.filter{ $0.dim <= dim }
        return SimplicialComplex(vertexSet, sub)
    }
    
    public func chainComplex<R: Ring>(type: R.Type) -> ChainComplex<Simplex, R> {
        typealias M = FreeModule<Simplex, R>
        typealias F = FreeModuleHom<Simplex, R>
        
        let dim = simplices.reduce(0){ max($0, $1.dim) }
        
        var chns: [[Simplex]] = (0 ... dim).map{_ in []}
        for s in simplices {
            chns[s.dim].append(s)
        }
        
        let bmaps: [F] = (0 ... dim).map { (i) -> F in
            let from = chns[i]
            let to = (i > 0) ? chns[i - 1] : []
            let matrix: TypeLooseMatrix<R> = boundaryMapMatrix(from, to)
            return F(domainBasis: from, codomainBasis: to, matrix: matrix)
        }
        
        return ChainComplex(chainBases: chns, boundaryMaps: bmaps)
    }
    
    public func cochainComplex<R: Ring>(type: R.Type) -> CochainComplex<Simplex, R> {
        typealias M = FreeModule<Simplex, R>
        typealias F = FreeModuleHom<Simplex, R>
        
        let dim = simplices.reduce(0){ max($0, $1.dim) }
        
        var chns: [[Simplex]] = (0 ... dim).map{_ in []}
        for s in simplices {
            chns[s.dim].append(s)
        }
        
        // Regard the basis of C_i as the dual basis of C^i.
        // Since <δf, c> = <f, ∂c>, the matrix is given by the transpose.
        
        let bmaps: [F] = (0 ... dim).map { (i) -> F in
            let from = chns[i]
            let to = (i < dim) ? chns[i + 1] : []
            let matrix: TypeLooseMatrix<R> = boundaryMapMatrix(to, from).transposed
            return F(domainBasis: from, codomainBasis: to, matrix: matrix)
        }
        
        return CochainComplex(chainBases: chns, boundaryMaps: bmaps)
    }
    
    private func boundaryMapMatrix<R: Ring>(_ from: [Simplex], _ to : [Simplex]) -> TypeLooseMatrix<R> {
        var matrix = TypeLooseMatrix(rows: to.count, cols: from.count) { _ in R.zero }
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

public extension Homology where chainType == DescendingChainType, A == Simplex, R: EuclideanRing {
    public init(_ s: SimplicialComplex, _ type: R.Type) {
        let c: ChainComplex<Simplex, R> = s.chainComplex(type: R.self)
        self.init(c)
    }
}

public extension Cohomology where chainType == AscendingChainType, A == Simplex, R: EuclideanRing {
    public init(_ s: SimplicialComplex, _ type: R.Type) {
        let c: CochainComplex<Simplex, R> = s.cochainComplex(type: R.self)
        self.init(c)
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
    let simplices =
        K1.simplices.map { s in V.simplex(indices: s.vertices.map{$0.index}) }
            + K2.simplices.map { s in V.simplex(indices: s.vertices.map{$0.index + n1})
    }
    return SimplicialComplex(V, simplices)
}

// product complex
public func *(K1: SimplicialComplex, K2: SimplicialComplex) -> SimplicialComplex {
    let (n1, n2) = (K1.vertexSet.vertices.count, K2.vertexSet.vertices.count)
    let V = VertexSet(number: n1 * n2)
    
    // discard simplices that are faces of others.
    let S1 = K1.simplices.filter{ s in K1.simplices.forAll{ t in t == s || !t.contains(s) } }
    let S2 = K2.simplices.filter{ s in K2.simplices.forAll{ t in t == s || !t.contains(s) } }
    let simplexPairs: [(Simplex, Simplex)] = S1.flatMap{ s in S2.map{ t in (s, t) } }
    
    let indexPairs: [[(Int, Int)]] = simplexPairs.flatMap{(s, t) -> [[(Int, Int)]] in
        (0 ... s.dim + t.dim).flatMap{ k -> [[(Int, Int)]] in
            // list of ordered indices [(i0 <= i1 <= ... <= ik), ... ]
            let Is: [[Int]] = multicombi(s.dim + 1, k + 1)
            let Js: [[Int]]  = multicombi(t.dim + 1, k + 1)
            
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
    }
    
    return SimplicialComplex(V, simplices)
}
