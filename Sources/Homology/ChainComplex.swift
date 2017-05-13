//
//  ChainComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/04.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// TODO also support <R: Field>
public struct ChainComplex<A: Hashable, R: Ring>: CustomStringConvertible {
    public typealias M = FreeModule<A, R>
    public typealias F = FreeModuleHom<A, R>
    
    fileprivate let chainBases: [[A]] // [[0-chain], [1-chain], ..., [n-chain]]
    fileprivate let boundaryMaps: [F] // [(d_0 = 0), (d_1 = C_1 -> C_0), ..., (d_n: C_n -> C_{n-1}), (d_{n+1} = 0)]
    
    public init(chainBases: [[A]], boundaryMaps: [F]) {
        self.chainBases = chainBases
        self.boundaryMaps = boundaryMaps
    }
    
    public init(chainBases: [[A]], boundaryMapTable: [[R]]) {
        let boundaryMaps = boundaryMapTable.enumerated().map { (i, table) -> FreeModuleHom<A, R> in
            let domainBasis  = chainBases[i]
            let codomainBasis = (i > 0) ? chainBases[i - 1] : []
            let matrix = TypeLooseMatrix<R>(rows: codomainBasis.count, cols: domainBasis.count, elements: table)
            return FreeModuleHom(domainBasis: domainBasis,
                                 codomainBasis: codomainBasis,
                                 matrix: matrix)
        }
        self.init(chainBases: chainBases, boundaryMaps: boundaryMaps)
    }
    
    public init(_ pairs: ([A], F)...) {
        self.chainBases = pairs.map{$0.0}
        self.boundaryMaps = pairs.map{$0.1}
    }
    
    public var dim: Int {
        return self.chainBases.count - 1
    }
    
    public func boundaryMap(_ i: Int) -> FreeModuleHom<A, R> {
        return (0 ... dim).contains(i) ? boundaryMaps[i] : F.zero
    }
    
    public func homology() -> Homology<A, R> {
        return Homology(self)
    }
    
    public var description: String {
        return chainBases.description
    }
}

public extension ChainComplex where R: EuclideanRing {
    public func cycles(_ i: Int) -> [M] {
        return boundaryMaps[i].kernelGenerators
    }
    
    public func boundaries(_ i: Int) -> [M] {
        return boundaryMaps[i + 1].imageGenerators
    }

    public func homology() -> Homology<A, R> {
        return Homology(self)
    }
}
