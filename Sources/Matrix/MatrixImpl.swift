//
//  MatrixImplementation.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/09.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class _MatrixImpl<_R: Ring> {
    public typealias R = _R
    
    public final let rows: Int
    public final let cols: Int
    public final var grid: [R]
    
    public required init(_ rows: Int, _ cols: Int, _ grid: [R]) {
        self.rows = rows
        self.cols = cols
        self.grid = grid
    }
    
    internal func createInstance(_ rows: Int, _ cols: Int, _ grid: [R]) -> Self {
        return type(of: self).init(rows, cols, grid)
    }
    
    internal func createInstance(_ grid: [R]) -> Self {
        return createInstance(rows, cols, grid)
    }
    
    internal func createInstance(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) -> Self {
        let grid = (0 ..< rows * cols).map { (index: Int) -> R in
            let (i, j) = index /% cols
            return g(i, j)
        }
        return createInstance(rows, cols, grid)
    }
    
    internal func createInstance(_ g: (Int, Int) -> R) -> Self {
        return createInstance(rows, cols, g)
    }
    
    public func copy() -> Self {
        return createInstance(grid)
    }
    
    internal func gridIndex(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(i: Int, j: Int) -> R {
        get { return grid[gridIndex(i, j)] }
        set { grid[gridIndex(i, j)] = newValue }
    }
    
    public func equals(_ b: _MatrixImpl<R>) -> Bool {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        return grid == b.grid
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
        var p = UnsafeMutablePointer(&grid)
        p += gridIndex(i0, 0)
        
        for _ in 0 ..< cols {
            p.pointee = r * p.pointee
            p += 1
        }
    }
    
    public func multiplyCol(at j0: Int, by r: R) {
        var p = UnsafeMutablePointer(&grid)
        p += gridIndex(0, j0)
        
        for _ in 0 ..< rows {
            p.pointee = r * p.pointee
            p += cols
        }
    }
    
    public func addRow(at i0: Int, to i1: Int, multipliedBy r: R) {
        var p0 = UnsafeMutablePointer(&grid)
        p0 += gridIndex(i0, 0)
        
        var p1 = UnsafeMutablePointer(&grid)
        p1 += gridIndex(i1, 0)
        
        for _ in 0 ..< cols {
            p1.pointee = p1.pointee + r * p0.pointee
            p0 += 1
            p1 += 1
        }
    }
    
    public func addCol(at j0: Int, to j1: Int, multipliedBy r: R) {
        var p0 = UnsafeMutablePointer(&grid)
        p0 += gridIndex(0, j0)
        
        var p1 = UnsafeMutablePointer(&grid)
        p1 += gridIndex(0, j1)
        
        for _ in 0 ..< rows {
            p1.pointee = p1.pointee + r * p0.pointee
            p0 += cols
            p1 += cols
        }
    }
    
    public func swapRows(_ i0: Int, _ i1: Int) {
        var p0 = UnsafeMutablePointer(&grid)
        p0 += gridIndex(i0, 0)
        
        var p1 = UnsafeMutablePointer(&grid)
        p1 += gridIndex(i1, 0)
        
        for _ in 0 ..< cols {
            let a = p0.pointee
            p0.pointee = p1.pointee
            p1.pointee = a
            p0 += 1
            p1 += 1
        }
    }
    
    public func swapCols(_ j0: Int, _ j1: Int) {
        var p0 = UnsafeMutablePointer(&grid)
        p0 += gridIndex(0, j0)
        
        var p1 = UnsafeMutablePointer(&grid)
        p1 += gridIndex(0, j1)
        
        for _ in 0 ..< rows {
            let a = p0.pointee
            p0.pointee = p1.pointee
            p1.pointee = a
            p0 += cols
            p1 += cols
        }
    }
    
    /*
    public func eliminate(mode: MatrixEliminationMode = .Both) -> BaseMatrixElimination<_MatrixImpl<R>> {
        fatalError("MatrixElimination is not impled for \(R.self).")
    }
 */
}
