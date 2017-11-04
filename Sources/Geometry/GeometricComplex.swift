//
//  GeometricComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/28.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol GeometricCell: FreeModuleBase {
    var dim: Int { get }
}

public extension GeometricCell {
    public var degree: Int { return dim }
}

public protocol GeometricComplex: CustomStringConvertible {
    associatedtype Cell: GeometricCell
    
    var dim: Int {get}
    
    func allCells(ofDim: Int) -> [Cell]
    func allCells(ascending: Bool) -> [Cell]
    func skeleton(_ dim: Int) -> Self
    
    func boundary<R: Ring>(ofCell: Cell) -> FreeModule<Cell, R> // override point
    func boundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<Cell, Cell, R>
    func boundaryMatrix<R: Ring>(_ i: Int) -> DynamicMatrix<R>
}

public extension GeometricComplex {
    public func allCells(ascending: Bool = true) -> [Cell] {
        let l = (ascending) ? Array(0 ... dim) : Array((0 ... dim).reversed())
        return l.flatMap{ allCells(ofDim: $0) }
    }
    
    public func boundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<Cell, Cell, R> {
        return FreeModuleHom { s in
            (s.dim == i) ? self.boundary(ofCell: s).map{ ($0, $1) } : []
        }
    }
    
    public func boundaryMatrix<R: Ring>(_ i: Int) -> DynamicMatrix<R> {
        let from = (i <= dim) ? allCells(ofDim: i) : []
        let to = (i > 0) ? allCells(ofDim: i - 1) : []
        return boundaryMatrix(from: from, to: to)
    }
    
    internal func boundaryMatrix<R: Ring>(from: [Cell], to: [Cell]) -> DynamicMatrix<R> {
        let toIndex = Dictionary(pairs: to.enumerated().map{($1, $0)}) // [toCell: toIndex]
        let components = from.enumerated().flatMap{ (j, s) -> [MatrixComponent<R>] in
            return boundary(ofCell: s).flatMap{ (e: (Cell, R)) -> MatrixComponent<R>? in
                let (t, value) = e
                return toIndex[t].flatMap{ i in (i, j, value) }
            }
        }
        
        return DynamicMatrix(rows: to.count, cols: from.count, type: .Sparse, components: components)
    }
    
    public var description: String {
        return "\(type(of: self))(dim: \(dim))"
    }
    
    public var detailDescription: String {
        return "\(description) {\n" +
            (0 ... dim)
                .map{ (i) -> (Int, [Cell]) in (i, allCells(ofDim: i)) }
                .map{ (i, cells) -> String in "\t\(i): " + cells.map{"\($0)"}.joined(separator: ", ")}
                .joined(separator: "\n")
            + "\n}"
    }
}

public extension ChainComplex where chainType == Descending {
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where A == C.Cell {
        let chain = (0 ... K.dim).map{ (i) -> (ChainBasis, BoundaryMap, BoundaryMatrix) in
            (K.allCells(ofDim: i), K.boundaryMap(i), K.boundaryMatrix(i))
        }
        self.init(chain)
    }
    
    public convenience init<C: GeometricComplex>(_ K: C, _ L: C, _ type: R.Type) where A == C.Cell {
        let chain = (0 ... K.dim).map{ (i) -> (ChainBasis, BoundaryMap, BoundaryMatrix) in
            
            let from = K.allCells(ofDim: i).subtract(L.allCells(ofDim: i))
            let to   = K.allCells(ofDim: i - 1).subtract(L.allCells(ofDim: i - 1))
            let map: BoundaryMap = K.boundaryMap(i)
            let matrix: BoundaryMatrix = K.boundaryMatrix(from: from, to: to)
            
            return (from, map, matrix)
        }
        self.init(chain)
    }
}

public extension CochainComplex where chainType == Ascending {
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where Dual<C.Cell> == A {
        let cochain = (0 ... K.dim).map{ (i) -> (ChainBasis, BoundaryMap, BoundaryMatrix) in
            let basis = K.allCells(ofDim: i).map{ Dual($0) }
            let matrix = R(intValue: (-1).pow(i + 1)) * K.boundaryMatrix(i + 1).transposed
            let map = BoundaryMap { d in
                let j = K.allCells(ofDim: i).index(of: d.base)!
                let basis = K.allCells(ofDim: i + 1).map{ Dual($0) }
                let values = matrix.colArray(j)
                return zip(basis, values).toArray()
            }
            
            return (basis, map, matrix)
        }
        self.init(cochain)
    }
}

public extension Homology where chainType == Descending {
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where C.Cell == A {
        let c = ChainComplex(K, type)
        self.init(c)
    }

    public convenience init<C: GeometricComplex>(_ K: C, _ L: C, _ type: R.Type) where C.Cell == A {
        let c = ChainComplex(K, L, type)
        self.init(c)
    }
}

public extension Cohomology where chainType == Ascending {
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where Dual<C.Cell> == A {
        let c = CochainComplex(K, type)
        self.init(c)
    }
}

public protocol GeometricComplexMap: Map where Domain == ComplexType.Cell, Codomain == ComplexType.Cell {
    associatedtype ComplexType: GeometricComplex
}
