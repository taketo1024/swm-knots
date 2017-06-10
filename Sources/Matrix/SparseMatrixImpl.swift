//
//  GridMatrixImpl.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//
//  cf. https://en.wikipedia.org/wiki/Sparse_matrix

import Foundation

public class _SparseMatrixImpl<R: Ring>: _MatrixImpl<R> {
    public typealias Component = (row: Int, col: Int, value: R)
    private var list: SortedArray<Component> // Sorted Coordinate List in strict order.
    
    private let comparator = {(a: Component, b: Component) -> Bool in a.row < b.row || (a.row == b.row && a.col < b.col) }

    public required init(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) {
        var sorted = Array<Component>()
        for i in 0 ..< rows {
            for j in 0 ..< cols {
                let a = g(i, j)
                if a != R.zero {
                    sorted.append((i, j, a))
                }
            }
        }
        
        list = SortedArray(sorted: sorted, areInIncreasingOrder: comparator)
        super.init(rows, cols, g)
    }
    
    public required init(_ rows: Int, _ cols: Int, _ list: SortedArray<Component>) {
        self.list = list
        super.init(rows, cols, {_,_ in R.zero})
    }
    
    public override func copy() -> Self {
        return type(of: self).init(rows, cols, list)
    }
    
    public override subscript(i: Int, j: Int) -> R {
        get {
            if let i = list.index(of: (i, j, R.zero)) {
                return list[i].value
            } else {
                return R.zero
            }
        } set {
            list.insert((i, j, newValue))
        }
    }
    
    public override func equals(_ b: _MatrixImpl<R>) -> Bool {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        guard let b = b as? _SparseMatrixImpl<R> else { fatalError() }
        
        // this is just `list == b.list` if (Int, Int, R) could be Equatable...
        
        if list.count != b.list.count {
            return false
        }
        
        for i in 0 ..< list.count {
            if list[i] != b.list[i] {
                return false
            }
        }
        
        return true
    }
    
    public override func add(_ b: _MatrixImpl<R>) -> Self {
        fatalError()
    }
    
    public override func negate() -> Self {
        fatalError()
    }
    
    public override func leftMul(_ r: R) -> Self {
        fatalError()
    }
    
    public override func rightMul(_ r: R) -> Self {
        fatalError()
    }
    
    public override func mul(_ b: _MatrixImpl<R>) -> Self {
        fatalError()
    }
    
    public override func transpose() -> Self {
        fatalError()
    }
    
    public override func leftIdentity() -> Self {
        fatalError()
    }
    
    public override func rightIdentity() -> Self {
        fatalError()
    }
    
    public override func rowArray(_ i: Int) -> [R] {
        fatalError()
    }
    
    public override func colArray(_ j: Int) -> [R] {
        fatalError()
    }
    
    public override func rowVector(_ i: Int) -> Self {
        fatalError()
    }
    
    public override func colVector(_ j: Int) -> Self {
        fatalError()
    }
    
    public override func submatrix(colsInRange c: CountableRange<Int>) -> Self {
        fatalError()
    }
    
    public override func submatrix(rowsInRange r: CountableRange<Int>) -> Self {
        fatalError()
    }
    
    public override func submatrix(inRange: (CountableRange<Int>, CountableRange<Int>)) -> Self {
        fatalError()
    }
    
    public override func multiplyRow(at i0: Int, by r: R) {
        fatalError()
    }
    
    public override func multiplyCol(at j0: Int, by r: R) {
        fatalError()
    }
    
    public override func addRow(at i0: Int, to i1: Int, multipliedBy r: R) {
        fatalError()
    }
    
    public override func addCol(at j0: Int, to j1: Int, multipliedBy r: R) {
        fatalError()
    }
    
    public override func swapRows(_ i0: Int, _ i1: Int) {
        fatalError()
    }
    
    public override func swapCols(_ j0: Int, _ j1: Int) {
        fatalError()
    }
}
