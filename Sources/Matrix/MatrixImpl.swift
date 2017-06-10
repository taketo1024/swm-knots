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
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        return createInstance() { (i, j) -> R in
            return self[i, j] + b[i, j]
        }
    }
    
    public func negate() -> Self {
        return createInstance() { (i, j) -> R in
            return -self[i, j]
        }
    }
    
    public func leftMul(_ r: R) -> Self {
        return createInstance() { (i, j) -> R in
            return r * self[i, j]
        }
    }
    
    public func rightMul(_ r: R) -> Self {
        return createInstance() { (i, j) -> R in
            return self[i, j] * r
        }
    }
    
    public func mul(_ b: _MatrixImpl<R>) -> Self {
        assert(self.cols == b.rows, "Mismatching matrix size.")
        return createInstance(rows, b.cols) { (i, k) -> R in
            return (0 ..< cols)
                .map({j in self[i, j] * b[j, k]})
                .reduce(0) {$0 + $1}
        }
    }
    
    public func transpose() -> Self {
        return createInstance(cols, rows) { self[$1, $0] }
    }
    
    public func leftIdentity() -> Self {
        return createInstance(rows, rows) { $0 == $1 ? 1 : 0 }
    }
    
    public func rightIdentity() -> Self {
        return createInstance(cols, cols) { $0 == $1 ? 1 : 0 }
    }
    
    public func rowArray(_ i: Int) -> [R] {
        return (0 ..< cols).map{ j in self[i, j] }
    }
    
    public func colArray(_ j: Int) -> [R] {
        return (0 ..< rows).map{ i in self[i, j] }
    }
    
    public func rowVector(_ i: Int) -> Self {
        return createInstance(1, cols){(_, j) -> R in
            return self[i, j]
        }
    }
    
    public func colVector(_ j: Int) -> Self {
        return createInstance(rows, 1){(i, _) -> R in
            return self[i, j]
        }
    }
    
    public func submatrix(colsInRange c: CountableRange<Int>) -> Self {
        return createInstance(self.rows, c.upperBound - c.lowerBound) {
            self[$0, $1 + c.lowerBound]
        }
    }
    
    public func submatrix(rowsInRange r: CountableRange<Int>) -> Self {
        return createInstance(r.upperBound - r.lowerBound, self.cols) {
            self[$0 + r.lowerBound, $1]
        }
    }
    
    public func submatrix(inRange: (CountableRange<Int>, CountableRange<Int>)) -> Self {
        let (r, c) = inRange
        return createInstance(r.upperBound - r.lowerBound, c.upperBound - c.lowerBound) {
            self[$0 + r.lowerBound, $1 + c.lowerBound]
        }
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
