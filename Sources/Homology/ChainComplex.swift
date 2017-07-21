//
//  ChainComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/04.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol ChainType {}
public struct   Descending : ChainType {}  // for ChainComplex   / Homology
public struct   Ascending  : ChainType {}  // for CochainComplex / Cohomology

public typealias   ChainComplex<A: Hashable, R: Ring> = _ChainComplex<Descending, A, R>
public typealias CochainComplex<A: Hashable, R: Ring> = _ChainComplex<Ascending,  A, R>

public final class _ChainComplex<chainType: ChainType, A: FreeModuleBase, R: Ring>: CustomStringConvertible {
    public typealias ChainBasis = [A]
    public typealias BoundaryMap = FreeModuleHom<A, R>
    
    private let chain: [(ChainBasis, BoundaryMap)]
    public  let offset: Int
    
    // root initializer
    public init(_ chain: [(ChainBasis, BoundaryMap)], offset: Int = 0) {
        self.chain = chain
        self.offset = offset
    }
    
    public var descending: Bool {
        return (chainType.self == Descending.self)
    }
    
    public var degree: Int {
        return chain.count + offset - 1
    }
    
    public func chainBasis(_ i: Int) -> ChainBasis {
        return (offset ... degree).contains(i) ? chain[i - offset].0 : []
    }
    
    public func boundaryMap(_ i: Int) -> BoundaryMap {
        switch i {
        case (offset ... degree):
            return chain[i - offset].1
            
        case degree + 1 where descending:
            let basis = chainBasis(degree)
            return BoundaryMap(domainBasis: [],
                               codomainBasis: basis,
                               matrix: DynamicMatrix<R>(rows: basis.count, cols: 0, grid: []))
            
        case offset - 1 where !descending:
            let basis = chainBasis(offset)
            return BoundaryMap(domainBasis: [],
                               codomainBasis: basis,
                               matrix: DynamicMatrix<R>(rows: basis.count, cols: 0, grid: []))
            
        default:
            return BoundaryMap.zero
        }
    }
    
    public var description: String {
        return chain.description
    }
}
