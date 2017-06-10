//
//  MatrixImplementation.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/09.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// Abstract class.
// Concretized by _GridMatrixImpl, _SparceMatrixImpl.

public class _MatrixImpl<R: Ring> {
    public final let rows: Int
    public final let cols: Int
    
    public required init(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) {
        self.rows = rows
        self.cols = cols
    }
    
    internal func createInstance(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) -> Self {
        return type(of: self).init(rows, cols, g)
    }
    
    internal func createInstance(_ g: (Int, Int) -> R) -> Self {
        return createInstance(rows, cols, g)
    }
    
    public func copy() -> Self {
        fatalError("implement in subclass.")
    }
    
    public subscript(i: Int, j: Int) -> R {
        get { fatalError("implement in subclass.") }
        set { fatalError("implement in subclass.") }
    }
    
    public func equals(_ b: _MatrixImpl<R>) -> Bool {
        fatalError("implement in subclass.")
    }
    
    public func add(_ b: _MatrixImpl<R>) -> Self {
        fatalError("implement in subclass.")
    }
    
    public func negate() -> Self {
        fatalError("implement in subclass.")
    }
    
    public func leftMul(_ r: R) -> Self {
        fatalError("implement in subclass.")
    }
    
    public func rightMul(_ r: R) -> Self {
        fatalError("implement in subclass.")
    }
    
    public func mul(_ b: _MatrixImpl<R>) -> Self {
        fatalError("implement in subclass.")
    }
    
    public func transpose() -> Self {
        fatalError("implement in subclass.")
    }
    
    public func leftIdentity() -> Self {
        fatalError("implement in subclass.")
    }
    
    public func rightIdentity() -> Self {
        fatalError("implement in subclass.")
    }
    
    public func rowArray(_ i: Int) -> [R] {
        fatalError("implement in subclass.")
    }
    
    public func colArray(_ j: Int) -> [R] {
        fatalError("implement in subclass.")
    }
    
    public func rowVector(_ i: Int) -> Self {
        fatalError("implement in subclass.")
    }
    
    public func colVector(_ j: Int) -> Self {
        fatalError("implement in subclass.")
    }
    
    public func submatrix(colsInRange c: CountableRange<Int>) -> Self {
        fatalError("implement in subclass.")
    }
    
    public func submatrix(rowsInRange r: CountableRange<Int>) -> Self {
        fatalError("implement in subclass.")
    }
    
    public func submatrix(inRange: (CountableRange<Int>, CountableRange<Int>)) -> Self {
        fatalError("implement in subclass.")
    }
    
    public func multiplyRow(at i0: Int, by r: R) {
        fatalError("implement in subclass.")
    }
    
    public func multiplyCol(at j0: Int, by r: R) {
        fatalError("implement in subclass.")
    }
    
    public func addRow(at i0: Int, to i1: Int, multipliedBy r: R) {
        fatalError("implement in subclass.")
    }
    
    public func addCol(at j0: Int, to j1: Int, multipliedBy r: R) {
        fatalError("implement in subclass.")
    }
    
    public func swapRows(_ i0: Int, _ i1: Int) {
        fatalError("implement in subclass.")
    }
    
    public func swapCols(_ j0: Int, _ j1: Int) {
        fatalError("implement in subclass.")
    }
    
    public func eliminate<n: _Int, m: _Int>(mode: MatrixEliminationMode) -> MatrixElimination<R, n, m> {
        fatalError("MatrixElimination is not supported for a general Ring.")
    }
    
    public func determinant() -> R {
        fatalError("determinant not yet impled for a general Ring.")
    }
    
    public final var description: String {
        return "[" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joined(separator: ", ")
        }).joined(separator: "; ") + "]"
    }
    
    public final var alignedDescription: String {
        return "[\t" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joined(separator: ",\t")
        }).joined(separator: "\n\t") + "]"
    }
}
