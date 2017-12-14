//
//  HomologyExactSequence.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/12.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias   HomologyExactSequence<A: FreeModuleBase, R: EuclideanRing> = _HomologyExactSequence<Descending, A, R>
public typealias CohomologyExactSequence<A: FreeModuleBase, R: EuclideanRing> = _HomologyExactSequence<Ascending , A, R>

public struct _HomologyExactSequence<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: Sequence, CustomStringConvertible {
    public typealias Object = _Homology<chainType, A, R>.Summand
    public typealias Arrow  = _HomologyMap<chainType, A, A, R>
    
    internal let H:    [_Homology<chainType, A, R>]       // [0,      1,      2]
    internal let map : [_HomologyMap<chainType, A, A, R>] // [0 -> 1, 1 -> 2, 2 -> 0]
    
    public let topDegree: Int
    public let bottomDegree: Int
    
    public init(_ chain0: _ChainComplex<chainType, A, R>, _ map0 : _ChainMap<chainType, A, A, R>,
                _ chain1: _ChainComplex<chainType, A, R>, _ map1 : _ChainMap<chainType, A, A, R>,
                _ chain2: _ChainComplex<chainType, A, R>, _ delta: _ChainMap<chainType, A, A, R>) {
        
        self.H    = [_Homology(chain0), _Homology(chain1), _Homology(chain2)]
        self.map  = [_HomologyMap(from: H[0], to: H[1], inducedFrom: map0),
                     _HomologyMap(from: H[1], to: H[2], inducedFrom: map1),
                     _HomologyMap(from: H[2], to: H[0], inducedFrom: delta)]
        
        self.topDegree    = Swift.max(chain0.topDegree, chain1.topDegree, chain2.topDegree)
        self.bottomDegree = Swift.min(chain0.offset,    chain1.offset,    chain2.offset)
    }
    
    internal func seqIndex(_ i: Int, _ n: Int) -> Int {
        return chainType.descending ? (topDegree - n) * 3 + i : (n - bottomDegree) * 3 + i
    }
    
    internal func gridIndex(_ k: Int) -> (Int, Int) {
        let (i, j) = (k >= 0) ? (k % 3, k / 3) : (k % 3 + 3, k / 3 - 1)
        return (i, chainType.descending ? topDegree - j : bottomDegree + j)
    }
    
    public subscript(i: Int, n: Int) -> Object {
        assert((0 ..< 3).contains(i))
        return H[i][n]
    }
    
    public subscript(k: Int) -> Object {
        return object(k)
    }
    
    public func object(_ k: Int) -> Object {
        let (i, n) = gridIndex(k)
        return H[i][n]
    }
    
    public func arrow(_ k: Int) -> Arrow {
        let i = gridIndex(k).0
        return map[i]
    }
    
    public func matrix(_ k: Int) -> ComputationalMatrix<R> {
        let from = object(k)
        let to   = object(k + 1)
        let map  = arrow(k)
        
        let comps = from.generators.enumerated().flatMap { (j, z) -> [MatrixComponent<R>] in
            let w = map.appliedTo(z)
            let vec = to.factorize(w.representative)
            return vec.enumerated().map{ (i, a) in (i, j, a) }
        }
        
        return ComputationalMatrix(rows: to.generators.count, cols: from.generators.count, components: comps)
    }
    
    internal var degrees: [Int] {
        return chainType.descending
            ? (bottomDegree ... topDegree).reversed().toArray()
            : (bottomDegree ... topDegree).toArray()
    }
    
    public func solve(_ i: Int) -> _Homology<chainType, A, R> {
        let H = self.H[i]
        for n in bottomDegree ..< topDegree {
            if let h = solve(i, n) {
                print("solved: \(H)[\(n)]: ", h.detailDescription)
            }
        }
        return H
    }

    public func solve(_ i: Int, _ n: Int) -> Object? {
        
        //     f0      f1        f2      f3
        // h0 ---> h1 ---> [h2] ---> h3 ---> h4  (exact)
        //
        // ==>
        //               i         f2
        // 0 -> Ker(f2) >--> [h2] -->> Im(f2) -> 0  (exact)
        //       = Im(f1)               = Ker(f3)
        //      ~= Coker(f0)
        
        let k = seqIndex(i, n)
        let (h0, h1, h3, h4) = (object(k - 2), object(k - 1), object(k + 1), object(k + 2))
        let (f0, f1, f2, f3) = (arrow(k - 2), arrow(k - 1), arrow(k), arrow(k + 1))
        let H2 = H[i]

        // trivial cases
        
        // h2 = 0
        if h1.isTrivial && h3.isTrivial {
            return Object.zero(H2)
        }
        
        // h1 ~= h2, f1: isom
        if h0.isTrivial && h3.isTrivial {
        }
        
        // h2 ~= h3, f2: isom
        if h1.isTrivial && h4.isTrivial {
        }
        
        return nil
    }
    
    public func assertExactness(at i: Int, _ n: Int, debug: Bool = false) {
        let k = seqIndex(i, n)
        let H1 = object(k)
        
        if H1.isTrivial {
            return
        }
        
        let (H0, H2) = (object(k - 1), object(k + 1))
        let (f0, f1) = (arrow(k - 1), arrow(k))
        
        debugLog(print: debug, "----------\nExactness at \(H[i])[\((n))]\n\(H0) -> \(H1) -> \(H2)\n----------")
        
        // Im ⊂ Ker
        for x in H0.generators {
            let y = f0.appliedTo(x)
            let z = f1.appliedTo(y)
            
            debugLog(print: debug, "\t\(x) ->\t\(y) ->\t\(z)")
            
            assert(z == H2.zero)
        }
        
        // Im ⊃ Ker
        // TODO

        debugLog(print: debug, "\n")
    }
    
    public func assertExactness(debug: Bool = false) {
        for n in degrees {
            for i in (0 ..< 3) {
                assertExactness(at: i, n, debug: debug)
            }
        }
    }
    
    public func makeIterator() -> AnyIterator<Object> {
        let lazy = (0 ..< (topDegree - bottomDegree + 1) * 3).lazy.map{ k in self.object(k) }
        return AnyIterator(lazy.makeIterator())
    }
    
    public var description: String {
        return "\(H[0]) -> \(H[1]) -> \(H[2])"
    }
    
    public var detailDescription: String {
        return "\(self.description)\n--------------------\n" + degrees.map { n in
            "\(n): \t\(H[0][n].description) -> \t\(H[1][n].description) -> \t\(H[2][n].description) -> "
        }.joined(separator: "\n") + "\t0"
    }
}
