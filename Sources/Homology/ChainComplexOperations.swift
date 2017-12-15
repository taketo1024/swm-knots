//
//  ChainComplexOperations.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public extension ChainComplex {
    public static func ⊕<B>(C1: _ChainComplex<chainType, A, R>, C2: _ChainComplex<chainType, B, R>) -> _ChainComplex<chainType, Sum<A, B>, R> {
        typealias T = Sum<A, B>
        typealias C = _ChainComplex<chainType, T, R>
        
        let offset = min(C1.offset, C2.offset)
        let degree = max(C1.topDegree, C2.topDegree)
        
        let chain = (offset ... degree).map { i -> (C.ChainBasis, C.BoundaryMap, C.BoundaryMatrix) in
            let basis: C.ChainBasis = C1.chainBasis(i).map{ a in Sum(a) } + C2.chainBasis(i).map{ b in Sum(b) }
            
            let (f1, f2) = (C1.boundaryMap(i), C2.boundaryMap(i))
            let map: C.BoundaryMap = C.BoundaryMap { c in
                switch c {
                case let ._1(a): return FreeModule( f1.appliedTo(a).map{ (a, r) in (._1(a), r) } )
                case let ._2(b): return FreeModule( f2.appliedTo(b).map{ (b, r) in (._2(b), r) } )
                }
            }
            
            let (A1, A2) = (C1.boundaryMatrix(i), C2.boundaryMatrix(i))
            let comps = A1.components + A2.components.map{ (i, j, a) in (A1.rows + i, A1.cols + j, a) }
            let matrix = ComputationalMatrix<R>(rows: A1.rows + A2.rows, cols: A1.cols + A2.cols, components: comps)
            
            return (basis, map, matrix)
        }
        
        return _ChainComplex<chainType, T, R>(name: "\(C1.name)⊕\(C2.name)", chain)
    }
    
    public static func ⊗<B>(C1: _ChainComplex<chainType, A, R>, C2: _ChainComplex<chainType, B, R>) -> _ChainComplex<chainType, Tensor<A, B>, R> {
        typealias T = Tensor<A, B>
        typealias C = _ChainComplex<chainType, T, R>
        
        let offset = C1.offset + C2.offset
        let degree = C1.topDegree + C2.topDegree
        
        let bases = (offset ... degree).map{ (k) -> C.ChainBasis in
            (offset ... k).flatMap{ i in
                C1.chainBasis(i).allCombinations(with: C2.chainBasis(k - i)).map{ $0 ⊗ $1 }
            }
        }
        
        let chain = (offset ... degree).map{ (k) -> (C.ChainBasis, C.BoundaryMap, C.BoundaryMatrix) in
            let map = (offset ... k).sum { i -> C.BoundaryMap in
                let j = k - i
                let (d1, d2) = (C1.boundaryMap(i), C2.boundaryMap(j))
                let (I1, I2) = (FreeModuleHom<A, A, R>{ a in (a.degree == i) ? FreeModule(a) : FreeModule.zero },
                                FreeModuleHom<B, B, R>{ b in (b.degree == j) ? FreeModule(b) : FreeModule.zero })
                let e = R(intValue: (-1).pow(i))
                return d1 ⊗ I2 + e * I1 ⊗ d2
            }
            let from = bases[k - offset]
            let next = chainType.target(k - offset)
            let to = (0 ..< bases.count).contains(next) ? bases[next] : []
            let components = from.enumerated().flatMap{ (j, a) -> [MatrixComponent<R>] in
                let y = map.appliedTo(a)
                return to.enumerated().map{ (i, b) in (i, j, y[b]) }
            }
            let matrix = ComputationalMatrix(rows: to.count, cols: from.count, components: components )
            return (from, map, matrix)
        }
        
        return _ChainComplex<chainType, T, R>(name: "\(C1.name)⊗\(C2.name)", chain)
    }
}

