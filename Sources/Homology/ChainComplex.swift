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

public typealias   ChainComplex<A: FreeModuleBase, R: Ring> = _ChainComplex<Descending, A, R>
public typealias CochainComplex<A: FreeModuleBase, R: Ring> = _ChainComplex<Ascending,  A, R>

public final class _ChainComplex<chainType: ChainType, A: FreeModuleBase, R: Ring>: Equatable, CustomStringConvertible {
    public typealias ChainBasis = [A]
    public typealias BoundaryMap = FreeModuleHom<R, A, A>
    
    private let chain: [BoundaryMap]
    public  let offset: Int
    
    // root initializer
    public init(_ chain: [BoundaryMap], offset: Int = 0) {
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
        return (offset ... degree).contains(i) ? chain[i - offset].domainBasis : []
    }
    
    public func boundaryMap(_ i: Int) -> BoundaryMap {
        switch i {
        case (offset ... degree):
            return chain[i - offset]
            
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
    
    @discardableResult
    public func assertComplex(debug: Bool = false) -> Bool {
        return (offset ... degree).forAll { i1 -> Bool in
            let i2 = descending ? i1 - 1 : i1 + 1
            let d1 = boundaryMap(i1)
            let d2 = boundaryMap(i2)
            
            if debug {
                print("----------")
                print("C\(i1) -> C\(i2)")
                print("----------")
                print("C\(i1) : \(d1.domainBasis)\n")
                for s in d1.domainBasis {
                    print("\t", s, " -> ", d1.appliedTo( FreeModule(s) ))
                }
                print()
                print("C\(i2) : \(d2.domainBasis)\n")
                for s in d2.domainBasis {
                    print("\t", s, " -> ", d2.appliedTo( FreeModule(s) ))
                }
                print()
            }
            
            assert(d1.codomainBasis == d2.domainBasis, "Bases of adjacent chains differ at: \(i1) -> \(i2)")
            
            let matrix = d2.matrix * d1.matrix
            assert(matrix.forAll { (_, _, a) in a == 0 } , "d\(i2)∘d\(i1) = \(matrix)")
            
            return true
        }
    }
    
    public static func ==<chainType: ChainType, A: FreeModuleBase, R: Ring>(lhs: _ChainComplex<chainType, A, R>, rhs: _ChainComplex<chainType, A, R>) -> Bool {
        let offset = min(lhs.offset, rhs.offset)
        let degree = max(lhs.degree, rhs.degree)
        return (offset ... degree).forAll { i in lhs.boundaryMap(i) == rhs.boundaryMap(i) }
    }
    
    public var description: String {
        return chain.description
    }
}

public func ⊗<chainType: ChainType, A: FreeModuleBase, B: FreeModuleBase, R: Ring>(C1: _ChainComplex<chainType, A, R>, C2: _ChainComplex<chainType, B, R>) -> _ChainComplex<chainType, Tensor<A, B>, R> {
    typealias NewChainBasis = [Tensor<A, B>]
    typealias NewBoundaryMap = FreeModuleHom<R, Tensor<A, B>, Tensor<A, B>>
    
    let offset = C1.offset + C2.offset
    let degree = C1.degree + C2.degree
    let chain = (offset ... degree).map{ (k) -> NewBoundaryMap in
        (offset ... k).map { (i) -> NewBoundaryMap in
            let (d1, d2) = (C1.boundaryMap(i), C2.boundaryMap(k - i))
            let (I1, I2) = (FreeModuleHom<R, A, A>.identity(basis: d1.domainBasis),
                            FreeModuleHom<R, B, B>.identity(basis: d2.domainBasis))
            let e = R(intValue: (-1).pow(i))
            return d1 ⊗ I2 + e * I1 ⊗ d2
        }.sumAll()
    }
    
    return _ChainComplex<chainType, Tensor<A, B>, R>(chain)
}


