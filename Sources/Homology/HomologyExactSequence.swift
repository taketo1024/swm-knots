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
    public typealias Element = (Object, Arrow)
    
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
    
    public subscript(i: Int, n: Int) -> Object {
        assert((0 ..< 3).contains(i))
        return H[i][n]
    }
    
    public func arrow(_ i: Int) -> Arrow {
        assert((0 ..< 3).contains(i))
        return map[i]
    }
    
    public func makeIterator() -> IndexingIterator<[Element]> {
        return degrees.flatMap { n in
            (0 ..< 3).map{ i in (H[i][n], map[i]) }
        }.makeIterator()
    }
    
    internal var degrees: [Int] {
        return chainType.descending
            ? (bottomDegree ... topDegree).reversed().toArray()
            : (bottomDegree ... topDegree).toArray()
    }
    
    public func assertExactness(at i1: Int, _ n1: Int, debug: Bool = false) {
        if H[i1][n1].isTrivial {
            return
        }
        
        let (i0, n0) = (i1 > 0) ? (i1 - 1, n1) : (2, n1 + 1)
        let (i2, n2) = (i1 < 2) ? (i1 + 1, n1) : (0, n1 - 1)
        
        let (H0, H1, H2) = (H[i0][n0], H[i1][n1], H[i2][n2])
        let (f0, f1) =     (map[i0],   map[i1])
        
        debugLog(print: debug, "----------\nExactness at \(H[i1])[\((n1))]\n\(H0) -> * \(H1) * -> \(H2)\n----------")
        
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
    
    public var description: String {
        return "\(H[0]) -> \(H[1]) -> \(H[2])"
    }
    
    public var detailDescription: String {
        return "\(self.description)\n--------------------\n" + degrees.map { n in
            "\(n): \t\(H[0][n].description) -> \t\(H[1][n].description) -> \t\(H[2][n].description) -> "
        }.joined(separator: "\n") + "\t0"
    }
}
