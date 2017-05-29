//
//  ChainComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/04.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol ChainType {}
public struct DescendingChainType: ChainType {} // for ChainComplexes
public struct AscendingChainType : ChainType {} // for CochainComplexes

public typealias ChainComplex<A: Hashable, R: Ring> = BaseChainComplex<DescendingChainType, A, R>
public typealias CochainComplex<A: Hashable, R: Ring> = BaseChainComplex<AscendingChainType, A, R>

public struct BaseChainComplex<chainType: ChainType, A: Hashable, R: Ring>: CustomStringConvertible {
    public typealias M = FreeModule<A, R>
    public typealias F = FreeModuleHom<A, R>
    
    public let chainBases: [[A]] // [[0-chain], [1-chain], ..., [n-chain]]
    public let boundaryMaps: [F] // [(d_0 = 0), (d_1 = C_1 -> C_0), ..., (d_n: C_n -> C_{n-1}), (d_{n+1} = 0)]
    
    // root initializer
    public init(chainBases: [[A]], boundaryMaps: [F]) {
        self.chainBases = chainBases
        self.boundaryMaps = boundaryMaps
    }
    
    public init(_ pairs: ([A], table: [R])...) {
        let descending = (chainType.self == DescendingChainType.self)
        
        let chainBases = pairs.map{$0.0}
        let boundaryMaps = pairs.map{$0.1}.enumerated().map { (i, table) -> FreeModuleHom<A, R> in
            let domainBasis  = chainBases[i]
            
            let j = (descending) ? (i - 1) : (i + 1)
            let codomainBasis = (0 <= j && j < chainBases.count) ? chainBases[j] : []
            
            let matrix = DynamicMatrix<R>(rows: codomainBasis.count, cols: domainBasis.count, grid: table)
            return FreeModuleHom(domainBasis: domainBasis,
                                 codomainBasis: codomainBasis,
                                 matrix: matrix)
        }
        self.init(chainBases: chainBases, boundaryMaps: boundaryMaps)
    }
    
    public init(_ pairs: ([A], F)...) {
        self.init(chainBases: pairs.map{$0.0}, boundaryMaps: pairs.map{$0.1})
    }
    
    public var dim: Int {
        return self.chainBases.count - 1
    }
    
    public var description: String {
        return chainBases.description
    }
}
