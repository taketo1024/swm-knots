//
//  HomologyExactSequence.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/12.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias   HomologyExactSequence<A: FreeModuleBase, B: FreeModuleBase, C: FreeModuleBase, R: EuclideanRing> = _HomologyExactSequence<Descending, A, B, C, R>
public typealias CohomologyExactSequence<A: FreeModuleBase, B: FreeModuleBase, C: FreeModuleBase, R: EuclideanRing> = _HomologyExactSequence<Ascending , A, B, C, R>

public struct _HomologyExactSequence<chainType: ChainType, A: FreeModuleBase, B: FreeModuleBase, C: FreeModuleBase, R: EuclideanRing>: CustomStringConvertible {
    public let H0: _Homology<chainType, A, R>
    public let H1: _Homology<chainType, B, R>
    public let H2: _Homology<chainType, C, R>
    
    public let map0: _HomologyMap<chainType, A, B, R>
    public let map1: _HomologyMap<chainType, B, C, R>
    public let connectingMap: _HomologyMap<chainType, C, A, R>
    
    public let topDegree: Int
    public let bottomDegree: Int
    
    public init(_ chain0: _ChainComplex<chainType, A, R>, _ map0: _ChainMap<chainType, A, B, R>,
                _ chain1: _ChainComplex<chainType, B, R>, _ map1: _ChainMap<chainType, B, C, R>,
                _ chain2: _ChainComplex<chainType, C, R>, _ connectingMap: _ChainMap<chainType, C, A, R>) {
        
        self.H0 = _Homology(chain0)
        self.H1 = _Homology(chain1)
        self.H2 = _Homology(chain2)
        
        self.map0 = _HomologyMap(from: H0, to: H1, inducedFrom: map0)
        self.map1 = _HomologyMap(from: H1, to: H2, inducedFrom: map1)
        self.connectingMap = _HomologyMap(from: H2, to: H0, inducedFrom: connectingMap)
        
        self.topDegree    = max(chain0.topDegree, chain1.topDegree, chain2.topDegree)
        self.bottomDegree = max(chain0.offset,    chain1.offset,    chain2.offset)
    }
    
    public var description: String {
        return "\(H0) -> \(H1) -> \(H2)"
    }
    
    public var detailDescription: String {
        let degrees = chainType.descending ? (bottomDegree ... topDegree).reversed().toArray() : (bottomDegree ... topDegree).toArray()
        return "\(self.description)\n" + degrees.map { i in
            "\(i): \t\(H0[i].description) -> \t\(H1[i].description) -> \t\(H2[i].description) -> "
        }.joined(separator: "\n") + "\t0"
    }
}
