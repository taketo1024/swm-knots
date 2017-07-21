//
//  GeometricComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/28.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol GeometricComplex: CustomStringConvertible, CustomDebugStringConvertible {
    associatedtype Cell: FreeModuleBase
    
    var dim: Int {get}
    
    func allCells(ofDim: Int) -> [Cell]
    func allCells(ascending: Bool) -> [Cell]
    func skeleton(_ dim: Int) -> Self
    
    func boundary<R: Ring>(ofCell: Cell) -> FreeModule<Cell, R> // override point
    func boundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<Cell, R>
    func coboundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<Cell, R>
    
    func chainComplex<R: Ring>(type: R.Type) -> ChainComplex<Cell, R>
    func cochainComplex<R: Ring>(type: R.Type) -> CochainComplex<Cell, R>
}

public extension GeometricComplex {
    public func allCells(ascending: Bool = true) -> [Cell] {
        let l = (ascending) ? Array(0 ... dim) : Array((0 ... dim).reversed())
        return l.flatMap{ allCells(ofDim: $0) }
    }
    
    public func boundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<Cell, R> {
        let from = allCells(ofDim: i)
        let to = (i > 0) ? allCells(ofDim: i - 1) : []
        let matrix: DynamicMatrix<R> = boundaryMapMatrix(i, from, to)
        return FreeModuleHom<Cell, R>(domainBasis: from, codomainBasis: to, matrix: matrix)
    }
    
    public func coboundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<Cell, R> {
        // Regard the basis of C_i as the dual basis of C^i.
        // Since <δf, c> = <f, ∂c>, the matrix is given by the transpose.
        
        let from = allCells(ofDim: i)
        let to = (i < dim) ? allCells(ofDim: i + 1) : []
        let matrix: DynamicMatrix<R> = boundaryMapMatrix(i + 1, to, from).transposed
        return FreeModuleHom<Cell, R>(domainBasis: from, codomainBasis: to, matrix: matrix)
    }
    
    private func boundaryMapMatrix<R: Ring>(_ i: Int, _ from: [Cell], _ to : [Cell]) -> DynamicMatrix<R> {
        let toIndex = Dictionary(pairs: to.enumerated().map{($1, $0)}) // [toCell: toIndex]
        
        let components = from.enumerated().flatMap{ (j, s) -> [MatrixComponent<R>] in
            return boundary(ofCell: s).map{ (e: (Cell, R)) -> MatrixComponent<R> in
                let (t, value) = e
                let i = toIndex[t]!
                return (i, j, value)
            }
        }
        
        return DynamicMatrix(rows: to.count, cols: from.count, type: .Sparse, components: components)
    }
    
    public func chainComplex<R: Ring>(type: R.Type) -> ChainComplex<Cell, R> {
        let chain = (0 ... dim).map{ (i) -> ([Cell], FreeModuleHom<Cell, R>) in (allCells(ofDim: i), boundaryMap(i)) }
        return ChainComplex<Cell, R>(chain)
    }
    
    public func cochainComplex<R: Ring>(type: R.Type) -> CochainComplex<Cell, R> {
        let chain = (0 ... dim).map{ (i) -> ([Cell], FreeModuleHom<Cell, R>) in (allCells(ofDim: i), coboundaryMap(i)) }
        return CochainComplex<Cell, R>(chain)
    }
    
    public var description: String {
        return "\(type(of: self))(dim: \(dim))"
    }
    
    public var debugDescription: String {
        return "\(description) {\n" +
            (0 ... dim)
                .map{ (i) -> (Int, [Cell]) in (i, allCells(ofDim: i)) }
                .map{ (i, cells) -> String in "\t\(i): " + cells.map{"\($0)"}.joined(separator: ", ")}
                .joined(separator: "\n")
            + "\n}"
    }
}

public extension Homology where chainType == DescendingChainType, R: EuclideanRing {
    public init<C: GeometricComplex>(_ s: C, _ type: R.Type) where C.Cell == A {
        let c: ChainComplex<A, R> = s.chainComplex(type: R.self)
        self.init(c)
    }
}

public extension Cohomology where chainType == AscendingChainType, R: EuclideanRing {
    public init<C: GeometricComplex>(_ s: C, _ type: R.Type) where C.Cell == A {
        let c: CochainComplex<A, R> = s.cochainComplex(type: R.self)
        self.init(c)
    }
}
