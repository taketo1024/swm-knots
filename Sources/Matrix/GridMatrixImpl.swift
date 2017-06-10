//
//  GridMatrixImpl.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class _GridMatrixImpl<R: Ring>: _MatrixImpl<R> {
    final var grid: [R]
    
    public required init(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) {
        self.grid = (0 ..< rows * cols).map { (index: Int) -> R in
            let (i, j) = index /% cols
            return g(i, j)
        }
        super.init(rows, cols, g)
    }
    
    public required init(_ rows: Int, _ cols: Int, _ grid: [R]) {
        self.grid = grid
        super.init(rows, cols, {_,_ in R.zero})
    }
    
    public override func copy() -> Self {
        return type(of: self).init(rows, cols, grid)
    }
    
    internal func gridIndex(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public override subscript(i: Int, j: Int) -> R {
        get { return grid[gridIndex(i, j)] }
        set { grid[gridIndex(i, j)] = newValue }
    }
    
    public override func equals(_ b: _MatrixImpl<R>) -> Bool {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        guard let b = b as? _GridMatrixImpl<R> else { fatalError() }
        return grid == b.grid
    }
    
    public override func add(_ b: _MatrixImpl<R>) -> Self {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        return createInstance() { (i, j) -> R in
            return self[i, j] + b[i, j]
        }
    }
    
    public override func negate() -> Self {
        return createInstance() { (i, j) -> R in
            return -self[i, j]
        }
    }
    
    public override func leftMul(_ r: R) -> Self {
        return createInstance() { (i, j) -> R in
            return r * self[i, j]
        }
    }
    
    public override func rightMul(_ r: R) -> Self {
        return createInstance() { (i, j) -> R in
            return self[i, j] * r
        }
    }
    
    public override func mul(_ b: _MatrixImpl<R>) -> Self {
        assert(self.cols == b.rows, "Mismatching matrix size.")
        return createInstance(rows, b.cols) { (i, k) -> R in
            return (0 ..< cols)
                .map({j in self[i, j] * b[j, k]})
                .reduce(0) {$0 + $1}
        }
    }
    
    public override func transpose() -> Self {
        return createInstance(cols, rows) { self[$1, $0] }
    }
    
    public override func leftIdentity() -> Self {
        return createInstance(rows, rows) { $0 == $1 ? 1 : 0 }
    }
    
    public override func rightIdentity() -> Self {
        return createInstance(cols, cols) { $0 == $1 ? 1 : 0 }
    }
    
    public override func rowArray(_ i: Int) -> [R] {
        return (0 ..< cols).map{ j in self[i, j] }
    }
    
    public override func colArray(_ j: Int) -> [R] {
        return (0 ..< rows).map{ i in self[i, j] }
    }
    
    public override func rowVector(_ i: Int) -> Self {
        return createInstance(1, cols){(_, j) -> R in
            return self[i, j]
        }
    }
    
    public override func colVector(_ j: Int) -> Self {
        return createInstance(rows, 1){(i, _) -> R in
            return self[i, j]
        }
    }
    
    public override func submatrix(colsInRange c: CountableRange<Int>) -> Self {
        return createInstance(self.rows, c.upperBound - c.lowerBound) {
            self[$0, $1 + c.lowerBound]
        }
    }
    
    public override func submatrix(rowsInRange r: CountableRange<Int>) -> Self {
        return createInstance(r.upperBound - r.lowerBound, self.cols) {
            self[$0 + r.lowerBound, $1]
        }
    }
    
    public override func submatrix(inRange: (CountableRange<Int>, CountableRange<Int>)) -> Self {
        let (r, c) = inRange
        return createInstance(r.upperBound - r.lowerBound, c.upperBound - c.lowerBound) {
            self[$0 + r.lowerBound, $1 + c.lowerBound]
        }
    }
    
    public override func multiplyRow(at i0: Int, by r: R) {
        var p = UnsafeMutablePointer(&grid)
        p += gridIndex(i0, 0)
        
        for _ in 0 ..< cols {
            p.pointee = r * p.pointee
            p += 1
        }
    }
    
    public override func multiplyCol(at j0: Int, by r: R) {
        var p = UnsafeMutablePointer(&grid)
        p += gridIndex(0, j0)
        
        for _ in 0 ..< rows {
            p.pointee = r * p.pointee
            p += cols
        }
    }
    
    public override func addRow(at i0: Int, to i1: Int, multipliedBy r: R) {
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
    
    public override func addCol(at j0: Int, to j1: Int, multipliedBy r: R) {
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
    
    public override func swapRows(_ i0: Int, _ i1: Int) {
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
    
    public override func swapCols(_ j0: Int, _ j1: Int) {
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
}
