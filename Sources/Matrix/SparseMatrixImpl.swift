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
    
    internal static var rowFirst: ((Component, Component) -> Bool) {
        return {(a: Component, b: Component) -> Bool in a.row < b.row || (a.row == b.row && a.col < b.col) }
    }
    
    public struct ComponentList: Sequence {
        public typealias Iterator = IndexingIterator<[Component]>
        var list: SortedArray<Component>
        
        init(_ components: [Component], sorted: Bool = true) {
            list = sorted ? SortedArray(  sorted: components, orderedBy: rowFirst)
                          : SortedArray(unsorted: components, orderedBy: rowFirst)
        }
        
        init(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) {
            var sorted = Array<Component>()
            for i in 0 ..< rows {
                for j in 0 ..< cols {
                    let a = g(i, j)
                    if a != R.zero {
                        sorted.append((i, j, a))
                    }
                }
            }
            self.init(sorted)
        }
        
        subscript(index: Int) -> Component {
            return list[index]
        }
        
        var count: Int {
            return list.count
        }
        
        var components: [Component] {
            return list.elements
        }
        
        func value(_ i: Int, _ j: Int) -> R {
            if let index = list.index(of: (i, j, R.zero)) {
                return list[index].value
            } else {
                return R.zero
            }
        }
        
        mutating func update(_ i: Int, _ j: Int, _ newValue: R) {
            if newValue == R.zero {
                let c: Component = (i, j, R.zero)
                return list.remove(c)
            } else {
                let c: Component = (i, j, newValue)
                if let index = list.index(of: c) {
                    list[index] = (i, j, newValue)
                } else {
                    list.insert(c)
                }
            }
        }
        
        func map(_ g: (Int, Int, R) -> (Int, Int, R)) -> ComponentList {
            return ComponentList( list.map{ (c) -> Component in g(c.row, c.col, c.value) }, sorted: false )
        }
        
        func mapValues(_ g: (R) -> R) -> ComponentList {
            return ComponentList( list.map{ (c) -> Component in (c.row, c.col, g(c.value))} )
        }
        
        func filter(_ g: (Int, Int, R) -> Bool) -> ComponentList {
            return ComponentList( list.filter{ c in g(c.row, c.col, c.value) } )
        }
        
        public func makeIterator() -> IndexingIterator<[Component]> {
            return list.elements.makeIterator()
        }
        
        static func == (a: ComponentList, b: ComponentList) -> Bool {
            if a.list.count != b.list.count {
                return false
            }
            
            for i in 0 ..< a.list.count {
                if a.list[i] != b.list[i] {
                    return false
                }
            }
            
            return true
        }
    }
    
    private var list: ComponentList
    
    public required init(_ rows: Int, _ cols: Int, _ grid: [R]) {
        self.list = ComponentList(rows, cols, {(i, j) in grid[i * cols + j]})
        super.init(rows, cols, grid)
    }
    
    public required init(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) {
        self.list = ComponentList(rows, cols, g)
        super.init(rows, cols, g)
    }
    
    public required init(_ rows: Int, _ cols: Int, _ components: [MatrixComponent<R>]) {
        self.list = ComponentList(components, sorted: false)
        super.init(rows, cols, components)
    }
    
    public required init(_ rows: Int, _ cols: Int, _ list: ComponentList) {
        self.list = list
        super.init(rows, cols, Array<R>())
    }
    
    public override func copy() -> Self {
        return type(of: self).init(rows, cols, list.components)
    }
    
    public override subscript(i: Int, j: Int) -> R {
        get { return list.value(i, j) }
        set { list.update(i, j, newValue) }
    }
    
    public override func equals(_ b: _MatrixImpl<R>) -> Bool {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        guard let _b = b as? _SparseMatrixImpl<R> else { return super.equals(b) }
        return list == _b.list
    }
    
    public override func add(_ b: _MatrixImpl<R>) -> _MatrixImpl<R> {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        guard let _b = b as? _SparseMatrixImpl<R> else { return super.add(b) }
        
        var array = Array<Component>()
        
        let (n1, n2) = (list.count, _b.list.count)
        var (i1, i2) = (0, 0)
        
        while i1 < n1 && i2 < n2 {
            let (c1, c2) = (list[i1], _b.list[i2])
            if (c1.row, c1.col) == (c2.row, c2.col) {
                array.append((c1.row, c1.col, c1.value + c2.value))
                (i1, i2) = (i1 + 1, i2 + 1)
            } else if _SparseMatrixImpl.rowFirst(c1, c2) {
                array.append(c1)
                i1 += 1
            } else {
                array.append(c2)
                i2 += 1
            }
        }
        
        // at this point, either i1 == n1 or i2 == n2
        
        while i1 < n1 {
            array.append(list[i1])
            i1 += 1
        }
        
        while i2 < n2 {
            array.append(_b.list[i2])
            i2 += 1
        }
        
        let result = ComponentList(array)
        return type(of: self).init(rows, cols, result)
    }
    
    public override func negate() -> _MatrixImpl<R> {
        let result = list.mapValues{ -$0 }
        return type(of: self).init(rows, cols, result)
    }
    
    public override func leftMul(_ r: R) -> _MatrixImpl<R> {
        let result = list.mapValues{ r * $0 }
        return type(of: self).init(rows, cols, result)
    }
    
    public override func rightMul(_ r: R) -> _MatrixImpl<R> {
        let result = list.mapValues{ $0 * r}
        return type(of: self).init(rows, cols, result)
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
        
        let aRows = self.list.components.group { $0.row }
        let bCols =   _b.list.components.group { $0.col }
        
        var array = [Component]()
        
        for i in aRows.keys.sorted() {
            for j in bCols.keys.sorted() {
                let (rowComps, colComps) = (aRows[i]!, bCols[j]!)
                let val = prod(rowComps, colComps)
                if val != 0 {
                    array.append( (i, j, val) )
                }
            }
        }
        
        let result = ComponentList(array)
        return type(of: self).init(rows, b.cols, result)
    }
    
    public override func transpose() -> _MatrixImpl<R> {
        let result = list.map{ ($1, $0, $2) }
        return type(of: self).init(rows, cols, result)
    }
    
    public override func leftIdentity() -> _MatrixImpl<R> {
        let result = ComponentList( (0 ..< rows).map{ (i) -> Component in (i, i, R.identity) } )
        return type(of: self).init(rows, rows, result)
    }
    
    public override func rightIdentity() -> _MatrixImpl<R> {
        let result = ComponentList( (0 ..< cols).map{ (i) -> Component in (i, i, R.identity) } )
        return type(of: self).init(cols, cols, result)
    }
    
    public override func submatrix(inRange range: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> _MatrixImpl<R> {
        let (rowRange, colRange) = range
        let (r0, r1) = (rowRange.lowerBound, rowRange.upperBound)
        let (c0, c1) = (colRange.lowerBound, colRange.upperBound)
        
        let result = list.filter{ (i, j, _) in rowRange.contains(i) && colRange.contains(j) }
                         .map{ (i, j, a) in (i - r0, j - c0, a)}
        
        return type(of: self).init(r1 - r0, c1 - c0, result)
    }
    
    public override func multiplyRow(at i0: Int, by r: R) {
        for c in list {
            let (i, j, value) = c
            if i == i0 {
                list.update(i, j, r * value)
            } else if i > i0 {
                break
            }
        }
    }
    
    public override func multiplyCol(at j0: Int, by r: R) {
        for c in list {
            let (i, j, value) = c
            if j == j0 {
                list.update(i, j, r * value)
            }
        }
    }
    
    public override func addRow(at i0: Int, to i1: Int, multipliedBy r: R) {
        let row = list.filter { (i, _, _) in i == i0 }
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
        let result = list.map{ (i, j, a) -> Component in
            switch i {
            case i0: return (i1, j, a)
            case i1: return (i0, j, a)
            default: return ( i, j, a)
            }
        }
        self.list = result
    }
    
    public override func swapCols(_ j0: Int, _ j1: Int) {
        let result = list.map{ (i, j, a) -> Component in
            switch j {
            case j0: return (i, j1, a)
            case j1: return (i, j0, a)
            default: return (i,  j, a)
            }
        }
        self.list = result
    }
}
