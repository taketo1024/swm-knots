//
//  GridMatrixImpl.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//
//  cf. https://en.wikipedia.org/wiki/Sparse_matrix

import Foundation

// MEMO currently not in use, since performs worse than GridMatrix. 

public class _SparseMatrixImpl<R: Ring>: _MatrixImpl<R> {
    public class Component: Equatable, CustomStringConvertible {    // a reference type.
        var row, col: Int
        var value: R {
            willSet { assert(newValue != R.zero) } // for debug
        }
        init(_ i: Int, _ j: Int, _ a: R) {
            (row, col, value) = (i, j, a)
        }
        init(_ t: (Int, Int, R)) {
            (row, col, value) = t
        }
        func copy() -> Component {
            return Component(row, col, value)
        }
        static public func == (a: Component, b: Component) -> Bool {
            return (a.row, a.col, a.value) == (b.row, b.col, b.value)
        }
        public var description: String {
            return "(\(row), \(col); \(value)"
        }
    }
    
    internal static var rowFirst: ((Component, Component) -> Bool) {
        return {(a: Component, b: Component) -> Bool in a.row < b.row || (a.row == b.row && a.col < b.col) }
    }
    
    internal static var colFirst: ((Component, Component) -> Bool) {
        return {(a: Component, b: Component) -> Bool in a.col < b.col || (a.col == b.col && a.row < b.row) }
    }
    
    public struct ComponentList: Sequence {
        public typealias Iterator = IndexingIterator<[Component]>
        private var list: SortedArray<Component>
        private var rowTable: [Int: SortedArray<Component>]
        private var colTable: [Int: SortedArray<Component>]
        
        init(_ components: [Component], sorted: Bool = true) {
            list = sorted ? SortedArray(  sorted: components, orderedBy: rowFirst)
                          : SortedArray(unsorted: components, orderedBy: rowFirst)
            
            rowTable = list.groupMap{ c in (c.row, c)}.mapValues{ SortedArray(sorted: $0, orderedBy: rowFirst) }
            colTable = list.groupMap{ c in (c.col, c)}.mapValues{ SortedArray(sorted: $0, orderedBy: colFirst) }
        }
        
        init(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) {
            var sorted = Array<Component>()
            for i in 0 ..< rows {
                for j in 0 ..< cols {
                    let a = g(i, j)
                    if a != R.zero {
                        sorted.append(Component(i, j, a))
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
        
        func get(_ i: Int, _ j: Int) -> R {
            if let index = list.index(of: Component(i, j, R.zero)) {
                return list[index].value
            } else {
                return R.zero
            }
        }
        
        mutating func set(_ i: Int, _ j: Int, _ value: R) {
            let c = Component(i, j, value)
            set(c)
        }
        
        mutating func set(_ c: Component) {
            if c.value == R.zero {
                remove(c)
            } else {
                if let index = list.index(of: c) {
                    let (i, j, value) = (c.row, c.col, c.value)
                    list[index].value = value
                    
                    let i0 = rowTable[i]!.index(of: c)!
                    rowTable[i]![i0].value = value
                    
                    let j0 = colTable[j]!.index(of: c)!
                    colTable[j]![j0].value = value
                    
                } else {
                    let (i, j) = (c.row, c.col)
                    list.insert(c)
                    
                    if case nil = rowTable[i]?.insert(c) {
                        rowTable[i] = SortedArray(sorted: [c], orderedBy: _SparseMatrixImpl.rowFirst)
                    }
                    if case nil = colTable[j]?.insert(c) {
                        colTable[j] = SortedArray(sorted: [c], orderedBy: _SparseMatrixImpl.colFirst)
                    }
                }
            }
        }
        
        mutating func remove(_ i: Int, _ j: Int) {
            let c = Component(i, j, R.zero)
            remove(c)
        }
        
        mutating func remove(_ c: Component) {
            if let index = list.index(of: c) {
                list.remove(at: index)
                rowTable[c.row]!.remove(c)
                colTable[c.col]!.remove(c)
            }
        }
        
        func copy() -> ComponentList {
            return ComponentList( list.map{ $0.copy() } )
        }
        
        func copy(mapping g: (Int, Int, R) -> (Int, Int, R)) -> ComponentList {
            return ComponentList( list.map{ c in Component( g(c.row, c.col, c.value) ) }, sorted: false )
        }
        
        func copy(mappingValues g: (R) -> R) -> ComponentList {
            return ComponentList( list.map{ c in Component(c.row, c.col, g(c.value))} )
        }
        
        func filter(_ g: (Int, Int, R) -> Bool) -> ComponentList {
            return ComponentList( list.filter{ c in g(c.row, c.col, c.value) } )
        }
        
        func rowComponents(in i: Int) -> [Component] {
            return rowTable[i].flatMap{ Array($0) } ?? []
        }
        
        func allRowComponents() -> [(Int, [Component])] {
            return rowTable.keys.sorted().map{ i in (i, rowComponents(in: i))}
        }
        
        func colComponents(in j: Int) -> [Component] {
            return colTable[j].flatMap{ Array($0) } ?? []
        }
        
        func allColComponents() -> [(Int, [Component])] {
            return colTable.keys.sorted().map{ j in (j, colComponents(in: j))}
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
        self.list = ComponentList(components.map{ Component($0.0, $0.1, $0.2) }, sorted: false)
        super.init(rows, cols, components)
    }
    
    public required init(_ rows: Int, _ cols: Int, _ list: ComponentList) {
        self.list = list
        super.init(rows, cols, Array<R>())
    }
    
    public override func copy() -> Self {
        return type(of: self).init(rows, cols, list.copy())
    }
    
    public override subscript(i: Int, j: Int) -> R {
        get { return list.get(i, j) }
        set { list.set(i, j, newValue) }
    }
    
    public override func equals(_ b: _MatrixImpl<R>) -> Bool {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        guard let _b = b as? _SparseMatrixImpl<R> else { return super.equals(b) }
        if !(list == _b.list) {
            print("a", list)
            print("b", _b.list)
        }
        
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
                array.append(Component(c1.row, c1.col, c1.value + c2.value))
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
        let result = list.copy{ -$0 }
        return type(of: self).init(rows, cols, result)
    }
    
    public override func leftMul(_ r: R) -> _MatrixImpl<R> {
        let result = list.copy{ r * $0 }
        return type(of: self).init(rows, cols, result)
    }
    
    public override func rightMul(_ r: R) -> _MatrixImpl<R> {
        let result = list.copy{ $0 * r }
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
        
        var array = [Component]()
        
        for (i, rowComps) in self.list.allRowComponents() {
            for (j, colComps) in _b.list.allColComponents() {
                let val = prod(rowComps, colComps)
                if val != 0 {
                    array.append( Component(i, j, val) )
                }
            }
        }
        
        let result = ComponentList(array)
        return type(of: self).init(rows, b.cols, result)
    }
    
    public override func transpose() -> _MatrixImpl<R> {
        let result = list.copy{ ($1, $0, $2) }
        return type(of: self).init(cols, rows, result)
    }
    
    public override func leftIdentity() -> _MatrixImpl<R> {
        let result = ComponentList( (0 ..< rows).map{ i in Component(i, i, R.identity) } )
        return type(of: self).init(rows, rows, result)
    }
    
    public override func rightIdentity() -> _MatrixImpl<R> {
        let result = ComponentList( (0 ..< cols).map{ i in Component(i, i, R.identity) } )
        return type(of: self).init(cols, cols, result)
    }
    
    // TODO
    public override func submatrix(inRange range: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> _MatrixImpl<R> {
        let (rowRange, colRange) = range
        let (r0, r1) = (rowRange.lowerBound, rowRange.upperBound)
        let (c0, c1) = (colRange.lowerBound, colRange.upperBound)
        
        let result = list.filter{ (i, j, _) in rowRange.contains(i) && colRange.contains(j) }
                         .copy  { (i, j, a) in (i - r0, j - c0, a)}
        
        return type(of: self).init(r1 - r0, c1 - c0, result)
    }
    
    public override func multiplyRow(at i0: Int, by r: R) {
        for c in list.rowComponents(in: i0) {
            self[c.row, c.col] = r * c.value
        }
    }
    
    public override func multiplyCol(at j0: Int, by r: R) {
        for c in list.colComponents(in: j0) {
            self[c.row, c.col] = r * c.value
        }
    }
    
    public override func addRow(at i0: Int, to i1: Int, multipliedBy r: R) {
        for c in list.rowComponents(in: i0) {
            let (j, a) = (c.col, c.value)
            self[i1, j] = self[i1, j] + r * a
        }
    }
    
    public override func addCol(at j0: Int, to j1: Int, multipliedBy r: R) {
        for c in list.colComponents(in: j0) {
            let (i, a) = (c.row, c.value)
            self[i, j1] = self[i, j1] + r * a
        }
    }
    
    public override func swapRows(_ i0: Int, _ i1: Int) {
        let row0 = list.rowComponents(in: i0)
        let row1 = list.rowComponents(in: i1)
        
        for c in (row0 + row1) {
            list.remove(c)
        }
        
        for c in row0 {
            c.row = i1
            list.set(c)
        }
        for c in row1 {
            c.row = i0
            list.set(c)
        }
    }
    
    public override func swapCols(_ j0: Int, _ j1: Int) {
        let col0 = list.colComponents(in: j0)
        let col1 = list.colComponents(in: j1)
        
        for c in (col0 + col1) {
            list.remove(c)
        }
        
        for c in col0 {
            c.col = j1
            list.set(c)
        }
        for c in col1 {
            c.col = j0
            list.set(c)
        }
    }
}

