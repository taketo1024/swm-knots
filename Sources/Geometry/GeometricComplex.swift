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
    func boundary<R: Ring>(_ type: R.Type) -> FreeModule<Self, R>
}

public extension GeometricCell {
    public var degree: Int { return dim }
}

public protocol GeometricComplex: CustomStringConvertible {
    associatedtype Cell: GeometricCell
    
    var name: String { get }
    var dim: Int { get }
    
    func contains(_ cell: Cell) -> Bool
    
    var allCells: [Cell] { get }
    func cells(ofDim: Int) -> [Cell]
    func skeleton(_ dim: Int) -> Self
    
    func boundaryMap<R: Ring>(_ i: Int, _ type: R.Type) -> FreeModuleHom<Cell, Cell, R>
    func boundaryMatrix<R: Ring>(_ i: Int, _ type: R.Type) -> ComputationalMatrix<R>
    
    func coboundary<R: Ring>(_ d: Dual<Cell>, _ type: R.Type) -> FreeModule<Dual<Cell>, R>
}

public extension GeometricComplex {
    public var name: String {
        return "_" // TODO
    }
    
    public func contains(_ cell: Cell) -> Bool {
        return cells(ofDim: cell.dim).contains(cell)
    }
    
    internal var validDims: [Int] {
        return (dim >= 0) ? (0 ... dim).toArray() : []
    }

    public var allCells: [Cell] {
        return validDims.flatMap{ cells(ofDim: $0) }
    }
    
    public func boundaryMap<R: Ring>(_ i: Int, _ type: R.Type) -> FreeModuleHom<Cell, Cell, R> {
        return FreeModuleHom { s in
            (s.dim == i) ? s.boundary(R.self) : FreeModule.zero
        }
    }
    
    public func boundaryMatrix<R: Ring>(_ i: Int, _ type: R.Type) -> ComputationalMatrix<R> {
        let from = (i <= dim) ? cells(ofDim: i) : []
        let to = (i > 0) ? cells(ofDim: i - 1) : []
        return partialBoundaryMatrix(from, to, R.self)
    }
    
    public func coboundary<R: Ring>(_ d: Dual<Cell>, _ type: R.Type) -> FreeModule<Dual<Cell>, R> {
        let s = d.base
        let to = cells(ofDim: d.degree + 1)
        let e = R(intValue: (-1).pow(d.degree + 1))
        let row = partialBoundaryMatrix(to, [s], R.self).multiply(e)
        return FreeModule( zip(to.map{ Dual($0) }, row.generateGrid()) )
    }
    
    internal func partialBoundaryMatrix<R: Ring>(_ from: [Cell], _ to: [Cell], _ type: R.Type) -> ComputationalMatrix<R> {
        let toIndex = Dictionary(pairs: to.enumerated().map{($1, $0)}) // [toCell: toIndex]
        let components = from.enumerated().flatMap{ (j, s) -> [MatrixComponent<R>] in
            return s.boundary(R.self).flatMap{ (e: (Cell, R)) -> MatrixComponent<R>? in
                let (t, value) = e
                return toIndex[t].flatMap{ i in (i, j, value) }
            }
        }
        
        return ComputationalMatrix(rows: to.count, cols: from.count, components: components)
    }
    
    public var description: String {
        return (name == "_") ? "\(type(of: self))" : name
    }
    
    public var detailDescription: String {
        return "\(description) {\n" +
            validDims.map{ (i) -> (Int, [Cell]) in (i, cells(ofDim: i)) }
                     .map{ (i, cells) -> String in "\t\(i): " + cells.map{"\($0)"}.joined(separator: ", ")}
                     .joined(separator: "\n")
            + "\n}"
    }
}
