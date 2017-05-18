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
            let matrix: TypeLooseMatrix<R> = boundaryMapMatrix(to, from).transpose
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
    static var point: SimplicialComplex {
        return SimplicialComplex.ball(dim: 0)
    }
    
    static func ball(dim: Int) -> SimplicialComplex {
        let V = VertexSet(number: dim + 1)
        let s = V.simplex(indices: Array(0...dim))
        return SimplicialComplex(V, [s], generate: true)
    }
    
    static func sphere(dim: Int) -> SimplicialComplex {
        let V = VertexSet(number: dim + 2)
        let ss = V.simplex(indices: Array(0...dim + 1)).skeleton(dim)
        return SimplicialComplex(V, ss, generate: true)
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
