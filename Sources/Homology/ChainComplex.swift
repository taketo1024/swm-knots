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
    
    private let chain: [([A], F)]
    public  let offset: Int
    
    // root initializer
    public init(_ chain: [([A], F)], offset: Int = 0) {
        self.chain = chain
        self.offset = offset
    }
    
    public var descending: Bool {
        return (chainType.self == DescendingChainType.self)
    }
    
    public var dim: Int {
        return chain.count + offset - 1
    }
    
    public func chainBasis(_ i: Int) -> [A] {
        return (offset ... dim).contains(i) ? chain[i - offset].0 : []
    }
    
    public func boundaryMap(_ i: Int) -> FreeModuleHom<A, R> {
        switch i {
        case (offset ... dim):
            return chain[i - offset].1
            
        case dim + 1 where descending:
            let basis = chainBasis(dim)
            return FreeModuleHom(domainBasis: [],
                                 codomainBasis: basis,
                                 matrix: DynamicMatrix<R>(rows: basis.count, cols: 0, grid: []))
            
        case offset - 1 where !descending:
            let basis = chainBasis(offset)
            return FreeModuleHom(domainBasis: [],
                                 codomainBasis: basis,
                                 matrix: DynamicMatrix<R>(rows: basis.count, cols: 0, grid: []))
            
        default:
            return FreeModuleHom.zero
        }
    }
    
    public var description: String {
        return chain.description
    }
}
