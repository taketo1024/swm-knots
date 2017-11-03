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
    public typealias BoundaryMap = FreeModuleHom<A, A, R>
    public typealias BoundaryMatrix = DynamicMatrix<R>
    
    internal let chain: [(basis: ChainBasis, map: BoundaryMap, matrix: BoundaryMatrix)]
    public  let offset: Int
    
    // root initializer
    public init(_ chain: [(ChainBasis, BoundaryMap, BoundaryMatrix)], offset: Int = 0) {
        self.chain = chain
        self.offset = offset
    }
    
    public var descending: Bool {
        return (chainType.self == Descending.self)
    }
    
    public var topDegree: Int {
        return chain.count + offset - 1
    }
    
    public func chainBasis(_ i: Int) -> ChainBasis {
        return (offset ... topDegree).contains(i) ? chain[i - offset].basis : []
    }
    
    public func boundaryMap(_ i: Int) -> BoundaryMap {
        return (offset ... topDegree).contains(i) ? chain[i - offset].map :BoundaryMap.zero
    }
    
    public func boundaryMatrix(_ i: Int) -> BoundaryMatrix {
        switch i {
        case (offset ... topDegree):
            return chain[i - offset].matrix
            
        case topDegree + 1 where descending:
            return BoundaryMatrix(rows: chainBasis(topDegree).count, cols: 0)
            
        case offset - 1 where !descending:
            return BoundaryMatrix(rows: chainBasis(offset).count, cols: 0)
            
        default:
            return BoundaryMatrix(rows: 0, cols: 0)
        }
    }
    
    public func shifted(_ d: Int) -> _ChainComplex<chainType, A, R> {
        return _ChainComplex.init(chain, offset: offset + d)
    }
    
    public func assertComplex(debug: Bool = false) {
        (offset ... topDegree).forEach { i1 in
            let i2 = descending ? i1 - 1 : i1 + 1
            let b1 = chainBasis(i1)
            let (d1, d2) = (boundaryMap(i1), boundaryMap(i2))
            let (m1, m2) = (boundaryMatrix(i1), boundaryMatrix(i2))
            
            if debug {
                print("----------")
                print("C\(i1) -> C\(i2)")
                print("----------")
                print("C\(i1) : \(b1)\n")
                for s in b1 {
                    let x = d1.appliedTo(s)
                    let y = d2.appliedTo(x)
                    print("\t\(s) ->\t\(x) ->\t\(y)")
                }
                print()
            }
            
            let matrix = m2 * m1
            assert(matrix.forAll { (_, _, a) in a == 0 } , "d\(i2)∘d\(i1) = \(matrix)")
        }
    }
    
    public static func ==<chainType, A, R>(lhs: _ChainComplex<chainType, A, R>, rhs: _ChainComplex<chainType, A, R>) -> Bool {
        let offset = min(lhs.offset, rhs.offset)
        let degree = max(lhs.topDegree, rhs.topDegree)
        return (offset ... degree).forAll { i in lhs.boundaryMap(i) == rhs.boundaryMap(i) }
    }
    
    public var description: String {
        return chain.description
    }
}

public extension ChainComplex where chainType == Descending {
    public var dual: CochainComplex<A, R> {
        return CochainComplex(chain.reversed(), offset: offset)
    }
}

public extension ChainComplex where chainType == Ascending {
    public var dual: ChainComplex<A, R> {
        return ChainComplex(chain.reversed(), offset: offset)
    }
}

/*
public extension ChainComplex {
    public static func ⊗<chainType, A, B, R>(C1: _ChainComplex<chainType, A, R>, C2: _ChainComplex<chainType, B, R>) -> _ChainComplex<chainType, Tensor<A, B>, R> {
        typealias NewChainBasis = [Tensor<A, B>]
        typealias NewBoundaryMap = FreeModuleHom<Tensor<A, B>, Tensor<A, B>, R>
        
        let offset = C1.offset + C2.offset
        let degree = C1.topDegree + C2.topDegree
        let chain = (offset ... degree).map{ (k) -> (NewChainBasis, NewBoundaryMap, BoundaryMatrix) in
            (offset ... k).map { (i) -> NewBoundaryMap in
                let (d1, d2) = (C1.boundaryMap(i), C2.boundaryMap(k - i))
                let (I1, I2) = (FreeModuleHom<A, A, R>.identity(basis: d1.domainBasis),
                                FreeModuleHom<B, B, R>.identity(basis: d2.domainBasis))
                let e = R(intValue: (-1).pow(i))
                return d1 ⊗ I2 + e * I1 ⊗ d2
                }.sumAll()
        }
        
        return _ChainComplex<chainType, Tensor<A, B>, R>(chain)
    }
}
*/
