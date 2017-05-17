//
//  SimplicialComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/17.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct SimplicialComplex {
    public let simplices: OrderedSet<Simplex>
    
    public init<S: Sequence>(_ simplices: S, generate: Bool = false) where S.Iterator.Element == Simplex {
        self.simplices = generate ?
            simplices.reduce(OrderedSet()) { $0 + $1.allSubsimplices() }
            : OrderedSet(simplices)
    }
    
    public func chainComplex<R: Ring>(type: R.Type) -> ChainComplex<Simplex, R> {
        typealias M = FreeModule<Simplex, R>
        typealias F = FreeModuleHom<Simplex, R>
        
        func sgn(_ i: Int) -> Int {
            return (i % 2 == 0) ? 1 : -1
        }
        
        let dim = simplices.reduce(0){ max($0, $1.dim) }
        
        var chns: [[Simplex]] = (0 ... dim).map{_ in []}
        for s in simplices {
            chns[s.dim].append(s)
        }
        
        let bmaps: [F] = (0 ... dim).map { (i) -> F in
            let from = chns[i]
            let map = Dictionary.generateBy(keys: from){ (s) -> M in
                return s.faces().enumerated().reduce(M.zero){ (res, el) -> M in
                    let (i, t) = el
                    return res + R(sgn(i)) * M(t)
                }
            }
            return F(domainBasis: chns[i], codomainBasis: (i > 0) ? chns[i - 1] : [], mapping: map)
        }
        
        return ChainComplex(chainBases: chns, boundaryMaps: bmaps)
    }
}

public extension Homology where A == Simplex, R: EuclideanRing {
    public init(_ s: SimplicialComplex, _ type: R.Type) {
        let c: ChainComplex<Simplex, R> = s.chainComplex(type: R.self)
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
        return SimplicialComplex([s], generate: true)
    }
    
    static func sphere(dim: Int) -> SimplicialComplex {
        let V = VertexSet(number: dim + 2)
        let ss = V.simplex(indices: Array(0...dim + 1)).skeleton(dim)
        return SimplicialComplex(ss, generate: true)
    }
}

