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

public typealias   ChainComplex<R: Ring, A: FreeModuleBase> = _ChainComplex<Descending, R, A>
public typealias CochainComplex<R: Ring, A: FreeModuleBase> = _ChainComplex<Ascending,  R, A>

public final class _ChainComplex<chainType: ChainType, R: Ring, A: FreeModuleBase>: Equatable, CustomStringConvertible {
    public typealias ChainBasis = [A]
    public typealias BoundaryMap = FreeModuleHom<R, A, A>
    
    internal let chain: [BoundaryMap]
    public  let offset: Int
    
    // root initializer
    public init(_ chain: [BoundaryMap], offset: Int = 0) {
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
        return (offset ... topDegree).contains(i) ? chain[i - offset].domainBasis : []
    }
    
    public func boundaryMap(_ i: Int) -> BoundaryMap {
        switch i {
        case (offset ... topDegree):
            return chain[i - offset]
            
        case topDegree + 1 where descending:
            let basis = chainBasis(topDegree)
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
    
    public func shifted(_ d: Int) -> _ChainComplex<chainType, R, A> {
        return _ChainComplex.init(chain, offset: offset + d)
    }
    
    @discardableResult
    public func assertComplex(debug: Bool = false) -> Bool {
        return (offset ... topDegree).forAll { i1 -> Bool in
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
    
    public static func ==<chainType: ChainType, R: Ring, A: FreeModuleBase>(lhs: _ChainComplex<chainType, R, A>, rhs: _ChainComplex<chainType, R, A>) -> Bool {
        let offset = min(lhs.offset, rhs.offset)
        let degree = max(lhs.topDegree, rhs.topDegree)
        return (offset ... degree).forAll { i in lhs.boundaryMap(i) == rhs.boundaryMap(i) }
    }
    
    public var description: String {
        return chain.description
    }
}

public extension ChainComplex where chainType == Descending {
    public var dual: CochainComplex<R, A> {
        return CochainComplex(chain.reversed(), offset: offset)
    }
}

public extension ChainComplex where chainType == Ascending {
    public var dual: ChainComplex<R, A> {
        return ChainComplex(chain.reversed(), offset: offset)
    }
}

public func ⊗<chainType: ChainType, R: Ring, A: FreeModuleBase, B: FreeModuleBase>(C1: _ChainComplex<chainType, R, A>, C2: _ChainComplex<chainType, R, B>) -> _ChainComplex<chainType, R, Tensor<A, B>> {
    typealias NewChainBasis = [Tensor<A, B>]
    typealias NewBoundaryMap = FreeModuleHom<R, Tensor<A, B>, Tensor<A, B>>
    
    let offset = C1.offset + C2.offset
    let degree = C1.topDegree + C2.topDegree
    let chain = (offset ... degree).map{ (k) -> NewBoundaryMap in
        (offset ... k).map { (i) -> NewBoundaryMap in
            let (d1, d2) = (C1.boundaryMap(i), C2.boundaryMap(k - i))
            let (I1, I2) = (FreeModuleHom<R, A, A>.identity(basis: d1.domainBasis),
                            FreeModuleHom<R, B, B>.identity(basis: d2.domainBasis))
            let e = R(intValue: (-1).pow(i))
            return d1 ⊗ I2 + e * I1 ⊗ d2
        }.sumAll()
    }
    
    return _ChainComplex<chainType, R, Tensor<A, B>>(chain)
}


