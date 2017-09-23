//
//  GeometricComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/28.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol GeometricCell: FreeModuleBase {
    var dim: Int {get}
}

public protocol GeometricComplex: class, CustomStringConvertible {
    associatedtype Cell: GeometricCell
    
    var dim: Int {get}
    
    func allCells(ofDim: Int) -> [Cell]
    func allCells(ascending: Bool) -> [Cell]
    func skeleton(_ dim: Int) -> Self
    
    func boundary<R: Ring>(ofCell: Cell) -> FreeModule<R, Cell> // override point
    func boundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<R, Cell, Cell>
    func coboundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<R, Dual<Cell>, Dual<Cell>>
    
    func chainComplex<R: Ring>(type: R.Type) -> ChainComplex<R, Cell>
    func cochainComplex<R: Ring>(type: R.Type) -> CochainComplex<R, Dual<Cell>>
}

public extension GeometricComplex {
    public func allCells(ascending: Bool = true) -> [Cell] {
        let l = (ascending) ? Array(0 ... dim) : Array((0 ... dim).reversed())
        return l.flatMap{ allCells(ofDim: $0) }
    }
    
    public func boundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<R, Cell, Cell> {
        let from = allCells(ofDim: i)
        let to = (i > 0) ? allCells(ofDim: i - 1) : []
        let matrix: DynamicMatrix<R> = boundaryMapMatrix(i, from, to)
        return FreeModuleHom(domainBasis: from, codomainBasis: to, matrix: matrix)
    }
    
    public func coboundaryMap<R: Ring>(_ i: Int) -> FreeModuleHom<R, Dual<Cell>, Dual<Cell>> {
        // Regard the basis of C_i as the dual basis of C^i.
        // Since <δf, c> = <f, ∂c>, the matrix is given by the transpose.
        
        let from = allCells(ofDim: i)
        let to = (i < dim) ? allCells(ofDim: i + 1) : []
        let matrix = R(intValue: (-1).pow(i + 1)) * boundaryMapMatrix(i + 1, to, from).transposed
        return FreeModuleHom(domainBasis: from.map{ Dual($0) }, codomainBasis: to.map{ Dual($0) }, matrix: matrix)
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

public extension GeometricComplex {
    public func chainComplex<R: Ring>(type: R.Type) -> ChainComplex<R, Cell> {
        typealias BoundaryMap = ChainComplex<R, Cell>.BoundaryMap
        let chain = (0 ... dim).map{ (i) -> BoundaryMap in boundaryMap(i) }
        return ChainComplex(chain)
    }
    
    public func cochainComplex<R: Ring>(type: R.Type) -> CochainComplex<R, Dual<Cell>> {
        typealias CoboundaryMap = CochainComplex<R, Dual<Cell>>.BoundaryMap
        let cochain = (0 ... dim).map{ (i) -> CoboundaryMap in coboundaryMap(i) }
        return CochainComplex(cochain)
    }
    
    public func chainComplex<R: Ring>(relativeTo sub: Self, type: R.Type) -> ChainComplex<R, Cell> {
        typealias BoundaryMap = ChainComplex<R, Cell>.BoundaryMap
        let chain = (0 ... dim).map{ (i) -> BoundaryMap in
            let d: BoundaryMap = boundaryMap(i)
            return d.restrictedTo(domainBasis:   allCells(ofDim: i).subtract(sub.allCells(ofDim: i)),
                                  codomainBasis: allCells(ofDim: i - 1).subtract(sub.allCells(ofDim: i - 1)))
        }
        return ChainComplex(chain)
    }
}

public extension Homology where chainType == Descending {
    public convenience init<C: GeometricComplex>(_ K: C, _ type: R.Type) where C.Cell == A {
        let c: ChainComplex<R, A> = K.chainComplex(type: R.self)
        self.init(c)
    }

    public convenience init<C: GeometricComplex>(_ K: C, _ L: C, _ type: R.Type) where C.Cell == A {
        let c: ChainComplex<R, A> = K.chainComplex(relativeTo: L, type: R.self)
        self.init(c)
    }
}

public extension Cohomology where chainType == Ascending {
    public convenience init<C: GeometricComplex>(_ s: C, _ type: R.Type) where Dual<C.Cell> == A {
        let c: CochainComplex<R, A>  = s.cochainComplex(type: R.self)
        self.init(c)
    }
}
