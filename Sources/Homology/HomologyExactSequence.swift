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
    public typealias Element = (_Homology<chainType, A, R>.Summand, _HomologyMap<chainType, A, A, R>)
    
    internal let H:    [_Homology<chainType, A, R>]       // [0,      1,      2]
    internal let map : [_HomologyMap<chainType, A, A, R>] // [0 -> 1, 1 -> 2, 2 -> 0]
    
    public let topDegree: Int
    public let bottomDegree: Int
    
    public init(_ chain0: _ChainComplex<chainType, A, R>, _ map0 : _ChainMap<chainType, A, A, R>,
                _ chain1: _ChainComplex<chainType, A, R>, _ map1 : _ChainMap<chainType, A, A, R>,
                _ chain2: _ChainComplex<chainType, A, R>, _ delta: _ChainMap<chainType, A, A, R>) {
        
        self.H    = [_Homology(chain0), _Homology(chain2), _Homology(chain2)]
        self.map  = [_HomologyMap(from: H[0], to: H[1], inducedFrom: map0),
                     _HomologyMap(from: H[1], to: H[2], inducedFrom: map1),
                     _HomologyMap(from: H[2], to: H[0], inducedFrom: delta)]
        
        self.topDegree    = Swift.max(chain0.topDegree, chain1.topDegree, chain2.topDegree)
        self.bottomDegree = Swift.min(chain0.offset,    chain1.offset,    chain2.offset)
    }
    
    public subscript(i: Int, j: Int) -> _Homology<chainType, A, R>.Summand {
        return H[i][j]
    }
    
    public func map(i: Int) -> _HomologyMap<chainType, A, A, R> {
        return map[i]
    }
    
    public func makeIterator() -> IndexingIterator<[Element]> {
        let degrees = chainType.descending ? (bottomDegree ... topDegree).reversed().toArray() : (bottomDegree ... topDegree).toArray()
        return degrees.flatMap { n in
            (0 ..< 3).map{ i in (H[i][n], map[i]) }
        }.makeIterator()
    }
    
    public func assertExactness(debug: Bool = false) {
        typealias S = _Homology<chainType, A, R>.Summand
        typealias F = _HomologyMap<chainType, A, A, R>
        
        // TODO this is not an exactness assertion.
        func _assert(_ H0: S, _ map0: F, _ H1: S, _ map1: F, _ H2: S) {
            if debug {
                print("\t\(H[0]) -> \(H[1]) -> \(H[2])")
            }
                
            for x in H0.generators {
                let y = map0.appliedTo(x)
                let z = map1.appliedTo(y)
                
                if debug {
                    print("\t\(x) ->\t\(y) ->\t\(z)")
                }
                
                assert(z == H2.zero)
            }
            
            if debug {
                print()
            }
        }
        
        for i in (bottomDegree ... topDegree) {
            let j = chainType.target(i)
            if debug {
                print("----------")
                print("\(i): \(H[0]) -> \(H[1]) -> \(H[2])")
                print("----------")
            }
            _assert(H[0][i], map[0], H[1][i], map[1], H[2][i])
            _assert(H[1][i], map[1], H[2][i], map[2], H[0][j])
            _assert(H[2][i], map[2], H[0][j], map[0], H[1][j])
        }
    }
    
    public var description: String {
        return "\(H[0]) -> \(H[1]) -> \(H[2])"
    }
    
    public var detailDescription: String {
        let degrees = chainType.descending ? (bottomDegree ... topDegree).reversed().toArray() : (bottomDegree ... topDegree).toArray()
        return "\(self.description)\n" + degrees.map { i in
            "\(i): \t\(H[0][i].description) -> \t\(H[1][i].description) -> \t\(H[2][i].description) -> "
        }.joined(separator: "\n") + "\t0"
    }
}
