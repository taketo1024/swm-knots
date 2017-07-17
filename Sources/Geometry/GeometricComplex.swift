//
//  GeometricComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/28.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol GeometricComplex {
    associatedtype A: FreeModuleBase
    
    var dim: Int {get}
    
    func allCells(ofDim: Int) -> [A]
    func skeleton(_ dim: Int) -> Self
    
    func boundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<A, R>
    func coboundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<A, R>
    func boundaryMapMatrix<R: Ring>(_ i: Int, _ from: [A], _ to : [A]) -> DynamicMatrix<R>
    
    func chainComplex<R: Ring>(type: R.Type) -> ChainComplex<A, R>
    func cochainComplex<R: Ring>(type: R.Type) -> CochainComplex<A, R>
}

public extension GeometricComplex {
    public func boundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<A, R> {
        let from = allCells(ofDim: i)
        let to = (i > 0) ? allCells(ofDim: i - 1) : []
        let matrix: DynamicMatrix<R> = boundaryMapMatrix(i, from, to)
        return FreeModuleHom<A, R>(domainBasis: from, codomainBasis: to, matrix: matrix)
    }
    
    public func coboundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<A, R> {
        // Regard the basis of C_i as the dual basis of C^i.
        // Since <δf, c> = <f, ∂c>, the matrix is given by the transpose.
        
        let from = allCells(ofDim: i)
        let to = (i < dim) ? allCells(ofDim: i + 1) : []
        let matrix: DynamicMatrix<R> = boundaryMapMatrix(i + 1, to, from).transposed
        return FreeModuleHom<A, R>(domainBasis: from, codomainBasis: to, matrix: matrix)
    }
    
    public func chainComplex<R: Ring>(type: R.Type) -> ChainComplex<A, R> {
        let chain = (0 ... dim).map{ (i) -> ([A], FreeModuleHom<A, R>) in (allCells(ofDim: i), boundaryMap(i)) }
        return ChainComplex<A, R>(chain)
    }
    
    public func cochainComplex<R: Ring>(type: R.Type) -> CochainComplex<A, R> {
        let chain = (0 ... dim).map{ (i) -> ([A], FreeModuleHom<A, R>) in (allCells(ofDim: i), coboundaryMap(i)) }
        return CochainComplex<A, R>(chain)
    }
}

public extension Homology where chainType == DescendingChainType, R: EuclideanRing {
    public init<C: GeometricComplex>(_ s: C, _ type: R.Type) where C.A == A {
        let c: ChainComplex<A, R> = s.chainComplex(type: R.self)
        self.init(c)
    }
}

public extension Cohomology where chainType == AscendingChainType, R: EuclideanRing {
    public init<C: GeometricComplex>(_ s: C, _ type: R.Type) where C.A == A {
        let c: CochainComplex<A, R> = s.cochainComplex(type: R.self)
        self.init(c)
    }
}
