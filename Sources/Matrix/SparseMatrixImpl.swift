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
    public typealias Component = MatrixComponent<R>
    
    internal static var lexLEQ: ((Component, Component) -> Bool) {
        return {(a: Component, b: Component) -> Bool in a.row < b.row || (a.row == b.row && a.col < b.col) }
    }
    
    private var list: SortedArray<Component> // Sorted Coordinate List
    
    public required init(_ rows: Int, _ cols: Int, _ grid: [R]) {
        self.list = _SparseMatrixImpl<R>.sortedArray(rows, cols, {(i, j) in grid[i * cols + j]})
        super.init(rows, cols, grid)
    }
    
    public required init(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) {
        self.list = _SparseMatrixImpl<R>.sortedArray(rows, cols, g)
        super.init(rows, cols, g)
    }
    
    public required init(_ rows: Int, _ cols: Int, _ components: [MatrixComponent<R>]) {
        self.list = _SparseMatrixImpl<R>.sortedArray(components, sort: true)
        super.init(rows, cols, components)
    }
    
    public required init(_ rows: Int, _ cols: Int, _ list: SortedArray<Component>) {
        self.list = list
        super.init(rows, cols, [R]())
    }
    
    public override func copy() -> Self {
        return type(of: self).init(rows, cols, list)
    }
    
    public override subscript(i: Int, j: Int) -> R {
        get {
            if let index = list.index(of: (i, j, 0)) {
                return list[index].value
            } else {
                return R.zero
            }
        } set {
            if newValue == R.zero {
                list.remove((i, j, 0))
            } else if let index = list.index(of: (i, j, 0)){
                list[index] = (i, j, newValue)
            } else {
                list.insert((i, j, newValue))
            }
        }
    }
    
    public override func equals(_ b: _MatrixImpl<R>) -> Bool {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        guard let _b = b as? _SparseMatrixImpl<R> else { return super.equals(b) }
        
        // this is just `list == b.list` if (Int, Int, R) could be Equatable...
        
        if list.count != _b.list.count {
            return false
        }
        
        for i in 0 ..< list.count {
            if list[i] != _b.list[i] {
                return false
            }
        }
        
        return true
    }
    
    public override func add(_ b: _MatrixImpl<R>) -> _MatrixImpl<R> {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        guard let _b = b as? _SparseMatrixImpl<R> else { return super.add(b) }
        
        var result = Array<Component>()
        
        let (n1, n2) = (list.count, _b.list.count)
        var (i1, i2) = (0, 0)
        
        while i1 < n1 && i2 < n2 {
            let (c1, c2) = (list[i1], _b.list[i2])
            if (c1.row, c1.col) == (c2.row, c2.col) {
                result.append((c1.row, c1.col, c1.value + c2.value))
                (i1, i2) = (i1 + 1, i2 + 1)
            } else if lexLEQ(c1, c2) {
                result.append(c1)
                i1 += 1
            } else {
                result.append(c2)
                i2 += 1
            }
        }
        
        // at this point, either i1 == n1 or i2 == n2
        
        while i1 < n1 {
            result.append(list[i1])
            i1 += 1
        }
        
        while i2 < n2 {
            result.append(_b.list[i2])
            i2 += 1
        }
        
        return type(of: self).init(rows, cols, sortedArray(result))
    }
    
    public override func negate() -> _MatrixImpl<R> {
        let result = list.map{ c -> Component in (c.row, c.col, -c.value)}
        return type(of: self).init(rows, cols, sortedArray(result))
    }
    
    public override func leftMul(_ r: R) -> _MatrixImpl<R> {
        let result = list.map{ c -> Component in (c.row, c.col, r * c.value)}
        return type(of: self).init(rows, cols, sortedArray(result))
    }
    
    public override func rightMul(_ r: R) -> _MatrixImpl<R> {
        let result = list.map{ c -> Component in (c.row, c.col, c.value * r)}
        return type(of: self).init(rows, cols, sortedArray(result))
    }
    
    public override func mul(_ b: _MatrixImpl<R>) -> _MatrixImpl<R> {
        assert(self.cols == b.rows, "Mismatching matrix size.")
        guard let _b = b as? _SparseMatrixImpl<R> else { return super.mul(b) }
        
        func prod(_ rowComps: [Component], _ colComps: [Component]) -> R {
            let (n1, n2) = (rowComps.count, colComps.count)
            var (i1, i2) = (0, 0)
            var result = R.zero
            
            while i1 < n1 && i2 < n2 {
                let (c1, c2) = (rowComps[i1], colComps[i2])
                if c1.col == c2.row {
                    result = result + c1.value * c2.value
                    (i1, i2) = (i1 + 1, i2 + 1)
                } else if c1.col < c2.row {
                    i1 += 1
                } else {
                    i2 += 1
                }
            }
            
            return result
        }
        
        let aRows = self.list.group { $0.row }
        let bCols =   _b.list.group { $0.col }
        
        var result = [Component]()
        
        for i in aRows.keys.sorted() {
            for j in bCols.keys.sorted() {
                let (rowComps, colComps) = (aRows[i]!, bCols[j]!)
                let val = prod(rowComps, colComps)
                if val != 0 {
                    result.append( (i, j, val) )
                }
            }
        }
        
        return type(of: self).init(rows, b.cols, sortedArray(result))
    }
    
    public override func transpose() -> _MatrixImpl<R> {
        let result = list.map{ c -> Component in (c.col, c.row, c.value)}
        return type(of: self).init(rows, cols, sortedArray(result, sort: true))
    }
    
    public override func leftIdentity() -> _MatrixImpl<R> {
        let result = (0 ..< rows).map{ (i) -> Component in (i, i, R.identity) }
        return type(of: self).init(rows, rows, sortedArray(result))
    }
    
    public override func rightIdentity() -> _MatrixImpl<R> {
        let result = (0 ..< cols).map{ (i) -> Component in (i, i, R.identity) }
        return type(of: self).init(cols, cols, sortedArray(result))
    }
    
    public override func rowVector(_ i: Int) -> _MatrixImpl<R> {
        let result = list.filter{ c in c.row == i }
        return type(of: self).init(1, cols, result)
    }
    
    public override func colVector(_ j: Int) -> _MatrixImpl<R> {
        let result = list.filter{ c in c.row == j }
        return type(of: self).init(rows, 1, result)
    }
    
    public override func submatrix(rowsInRange rowRange: CountableRange<Int>) -> _MatrixImpl<R> {
        let result = list.filter{ c in rowRange.contains(c.row) }
        return type(of: self).init(rowRange.upperBound - rowRange.lowerBound, cols, result)
    }
    
    public override func submatrix(colsInRange colRange: CountableRange<Int>) -> _MatrixImpl<R> {
        let result = list.filter{ c in colRange.contains(c.col) }
        return type(of: self).init(rows, colRange.upperBound - colRange.lowerBound, result)
    }
    
    public override func submatrix(inRange range: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> _MatrixImpl<R> {
        let (rowRange, colRange) = range
        let result = list.filter{ c in rowRange.contains(c.row) && colRange.contains(c.col) }
        return type(of: self).init(rowRange.upperBound - rowRange.lowerBound, colRange.upperBound - colRange.lowerBound, result)
    }
    
    public override func multiplyRow(at i0: Int, by r: R) {
        for index in 0 ..< list.count {
            let (i, j, value) = list[index]
            if i == i0 {
                list[index] = (i, j, r * value)
            } else if i > i0 {
                break
            }
        }
    }
    
    public override func multiplyCol(at j0: Int, by r: R) {
        for index in 0 ..< list.count {
            let (i, j, value) = list[index]
            if j == j0 {
                list[index] = (i, j, r * value)
            }
        }
    }
    
    public override func addRow(at i0: Int, to i1: Int, multipliedBy r: R) {
        let row = list.filter { c in c.row == i0 }
        for (_, j, a) in row {
            self[i1, j] = self[i1, j] + r * a
        }
    }
    
    public override func addCol(at j0: Int, to j1: Int, multipliedBy r: R) {
        let col = list.filter { c in c.col == j0 }
        for (i, _, a) in col {
            self[i, j1] = self[i, j1] + r * a
        }
    }
    
    public override func swapRows(_ i0: Int, _ i1: Int) {
        let result = list.map{ c -> Component in
            switch c.row {
            case i0: return (i1, c.col, c.value)
            case i1: return (i0, c.col, c.value)
            default: return c
            }
        }
        self.list = sortedArray(result, sort: true)
    }
    
    public override func swapCols(_ j0: Int, _ j1: Int) {
        let result = list.map{ c -> Component in
            switch c.col {
            case j0: return (c.row, j1, c.value)
            case j1: return (c.row, j0, c.value)
            default: return c
            }
        }
        self.list = sortedArray(result, sort: true)
    }
    
    // convenience funcs 
    
    internal var lexLEQ: ((Component, Component) -> Bool) {
        return _SparseMatrixImpl<R>.lexLEQ
    }

    internal static func sortedArray(_ array: Array<Component>, sort: Bool = false) -> SortedArray<Component> {
        return sort ? SortedArray<Component>(unsorted: array, areInIncreasingOrder: lexLEQ)
                    : SortedArray<Component>(  sorted: array, areInIncreasingOrder: lexLEQ)
    }
    
    internal func sortedArray(_ array: Array<Component>, sort: Bool = false) -> SortedArray<Component> {
        return _SparseMatrixImpl<R>.sortedArray(array, sort: sort)
    }
    
    internal static func sortedArray(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) -> SortedArray<Component> {
        var sorted = Array<Component>()
        for i in 0 ..< rows {
            for j in 0 ..< cols {
                let a = g(i, j)
                if a != R.zero {
                    sorted.append((i, j, a))
                }
            }
        }
        
        return sortedArray(sorted)
    }
    
}
