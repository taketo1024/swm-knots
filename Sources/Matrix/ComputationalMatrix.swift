//
//  RowSortedMatrix.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/10/16.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public enum ComputationalMatrixAlignment {
    case Rows
    case Cols
}

public final class ComputationalMatrix<R: Ring>: Equatable, CustomStringConvertible {
    public let rows: Int
    public let cols: Int
    
    internal var align: ComputationalMatrixAlignment
    internal var rowTable: [Int: [(col: Int, value: R)]]
    internal var colTable: [Int: [(row: Int, value: R)]]

    public subscript(i: Int, j: Int) -> R {
        switch align {
        case .Rows :
            return rowTable[i]?.first{ $0.col == j }?.value ?? 0 // TODO use binary search
        case .Cols:
            return colTable[j]?.first{ $0.row == i }?.value ?? 0 // TODO use binary search
        }
    }
    
    public convenience init<n, m>(_ a: Matrix<n, m, R>, align: ComputationalMatrixAlignment = .Rows) {
        self.init(rows: a.rows, cols: a.cols, grid: a.grid, align: align)
    }
    
    public convenience init(rows: Int, cols: Int, grid: [R], align: ComputationalMatrixAlignment = .Rows) {
        let components = grid.enumerated().flatMap{ (k, a) -> MatrixComponent<R>? in
            (a != R.zero) ? (k / cols, k % cols, a) : nil
        }
        self.init(rows: rows, cols: cols, components: components, align: align)
    }
    
    public init<S: Sequence>(rows: Int, cols: Int, components: S, align: ComputationalMatrixAlignment = .Rows) where S.Element == MatrixComponent<R> {
        self.rows = rows
        self.cols = cols
        
        self.align = align
        self.rowTable = [:]
        self.colTable = [:]

        for (i, j, a) in components {
            if a == R.zero { continue }
            add(i, j, a)
        }
        
        sort()
    }

    internal func add(_ i: Int, _ j: Int, _ a: R) {
        switch align {
        case .Rows:
            if rowTable[i] == nil {
                rowTable[i] = []
            }
            rowTable[i]!.append( (j, a) )
        case .Cols:
            if colTable[j] == nil {
                colTable[j] = []
            }
            colTable[j]!.append( (i, a) )
        }
    }

    internal func sort() {
        switch align {
        case .Rows:
            for (i, list) in rowTable {
                rowTable[i] = list.sorted{ (e1, e2) in e1.col < e2.col }
            }
        case .Cols:
            for (j, list) in colTable {
                colTable[j] = list.sorted{ (e1, e2) in e1.row < e2.row }
            }
        }
    }
    
    public static func identity(_ n: Int, align: ComputationalMatrixAlignment = .Rows) -> ComputationalMatrix<R> {
        let components = (0 ..< n).map{ i in MatrixComponent(i, i, R.identity)}
        return ComputationalMatrix(rows: n, cols: n, components: components, align: align)
    }
    
    public var toGrid: [R] {
        var grid = Array(repeating: R.zero, count: rows * cols)
        switch align {
        case .Rows:
            for (i, list) in rowTable {
                for (j, a) in list {
                    grid[i * cols + j] = a
                }
            }
        case .Cols:
            for (j, list) in colTable {
                for (i, a) in list {
                    grid[i * cols + j] = a
                }
            }
        }
        return grid
    }
    
    public var isDiagonal: Bool {
        switch align {
        case .Rows:
            return rowTable.forAll { (i, list) in (list.count == 1) && list.first!.col == i }
        case .Cols:
            return colTable.forAll { (j, list) in (list.count == 1) && list.first!.row == j }
        }
    }
    
    public var diagonal: [R] {
        switch align {
        case .Rows:
            return (0 ..< rowTable.count).map{ i in rowTable[i]!.first!.value }
        case .Cols:
            return (0 ..< colTable.count).map{ j in colTable[j]!.first!.value }
        }
    }
    
    public func switchAlignment(_ align: ComputationalMatrixAlignment) {
        if self.align == align {
            return
        }
        
        self.align = align
        
        switch align {
        case .Rows:
            rowTable = [:]
            for (j, list) in colTable {
                for (i, a) in list {
                    add(i, j, a)
                }
            }
            colTable = [:]
        case .Cols:
            colTable = [:]
            for (i, list) in rowTable {
                for (j, a) in list {
                    add(i, j, a)
                }
            }
            rowTable = [:]
        }
        
        sort()
    }
    
    public func multiplyRow(at i0: Int, by r: R) {
        switchAlignment(.Rows)
        
        if rowTable[i0] == nil {
            return
        }
        
        let n = rowTable[i0]!.count
        var p = UnsafeMutablePointer(&rowTable[i0]!)
        
        for _ in 0 ..< n {
            let (j, a) = p.pointee
            p.pointee = (j, r * a)
            p += 1
        }
    }
    
    public func multiplyCol(at j0: Int, by r: R) {
        switchAlignment(.Cols)
        
        if colTable[j0] == nil {
            return
        }
        
        let n = colTable[j0]!.count
        var p = UnsafeMutablePointer(&colTable[j0]!)
        
        for _ in 0 ..< n {
            let (i, a) = p.pointee
            p.pointee = (i, r * a)
            p += 1
        }
    }
    
    public func addRow(at i0: Int, to i1: Int, multipliedBy r: R = R.identity) {
        switchAlignment(.Rows)
        
        guard let r0 = rowTable[i0] else {
            return
        }
        
        guard let r1 = rowTable[i1] else {
            rowTable[i1] = r0.map{ ($0.col, r * $0.value )}
            return
        }
        
        var result: [(col: Int, value: R)] = []
        
        var (p0, p1) = (UnsafePointer(r0), UnsafePointer(r1))
        var (k0, k1) = (0, 0) // counters
        let (n0, n1) = (r0.count, r1.count)
        
        while k0 < n0 || k1 < n1 {
            let b = (k0 < n0 && k1 < n1)
            if b && (p0.pointee.col == p1.pointee.col) {
                let j0 = p0.pointee.col
                let (a0, a1) = (p0.pointee.value, p1.pointee.value)
                let value = r * a0 + a1
                
                if value != 0 {
                    result.append( (j0, value) )
                }
                
                p0 += 1
                p1 += 1
                k0 += 1
                k1 += 1
                
            } else if (k1 >= n1) || (b && p0.pointee.col < p1.pointee.col) {
                let j0 = p0.pointee.col
                let a0 = p0.pointee.value
                result.append( (j0, r * a0) )
                
                p0 += 1
                k0 += 1
                
            } else if (k0 >= n0) || (b && p0.pointee.col > p1.pointee.col) {
                let j1 = p1.pointee.col
                let a1 = p1.pointee.value
                result.append( (j1, a1) )
                
                p1 += 1
                k1 += 1
                
            }
        }
        
        rowTable[i1] = result
    }
    
    public func addCol(at j0: Int, to j1: Int, multipliedBy r: R = R.identity) {
        switchAlignment(.Cols)
        
        guard let c0 = colTable[j0] else {
            return
        }
        
        guard let c1 = colTable[j1] else {
            colTable[j1] = c0.map{ (i, a) in (i, r * a) }
            return
        }
        
        var result: [(row: Int, value: R)] = []
        
        var (p0, p1) = (UnsafePointer(c0), UnsafePointer(c1))
        var (k0, k1) = (0, 0) // counters
        let (n0, n1) = (c0.count, c1.count)
        
        while k0 < n0 || k1 < n1 {
            let b = (k0 < n0 && k1 < n1)
            if b && (p0.pointee.row == p1.pointee.row) {
                let i0 = p0.pointee.row
                let (a0, a1) = (p0.pointee.value, p1.pointee.value)
                let value = r * a0 + a1
                
                if value != 0 {
                    result.append( (i0, value) )
                }
                
                p0 += 1
                p1 += 1
                k0 += 1
                k1 += 1
                
            } else if (k1 >= n1) || (b && p0.pointee.row < p1.pointee.row) {
                let i0 = p0.pointee.row
                let a0 = p0.pointee.value
                result.append( (i0, r * a0) )
                
                p0 += 1
                k0 += 1
                
            } else if (k0 >= n0) || (b && p0.pointee.row > p1.pointee.row) {
                let i1 = p1.pointee.row
                let a1 = p1.pointee.value
                result.append( (i1, a1) )
                
                p1 += 1
                k1 += 1
                
            }
        }
        
        colTable[j1] = result
    }
    
    public func swapRows(_ i0: Int, _ i1: Int) {
        switchAlignment(.Rows)
        
        let r0 = rowTable[i0]
        rowTable[i0] = rowTable[i1]
        rowTable[i1] = r0
    }
    
    public func swapCols(_ j0: Int, _ j1: Int) {
        switchAlignment(.Cols)
        
        let r0 = colTable[j0]
        colTable[j0] = colTable[j1]
        colTable[j1] = r0
    }
    
    public func enumerate(row i0: Int, fromCol j0: Int) -> AnySequence<(col: Int, value: R)> {
        switch align {
        case .Rows:
            if let row = rowTable[i0] {
                return AnySequence(row.lazy.filter{ (col, _) in col >= j0})
            } else {
                return AnySequence([])
            }
        case .Cols:
            return AnySequence((j0 ..< cols).lazy.flatMap{ j -> (col: Int, value: R)? in
                if let (i, a) = self.colTable[j]?.first, i == i0 {
                    return (j, a)
                } else {
                    return nil
                }
            })
        }
    }
    
    public func enumerate(col j0: Int, fromRow i0: Int) -> AnySequence<(row: Int, value: R)> {
        switch align {
        case .Rows:
            return AnySequence((i0 ..< rows).lazy.flatMap{ i -> (row: Int, value: R)? in
                if let (j, a) = self.rowTable[i]?.first, j == j0 {
                    return (i, a)
                } else {
                    return nil
                }
            })
        case .Cols:
            if let col = colTable[j0] {
                return AnySequence(col.lazy.filter{ (row, _) in row >= i0})
            } else {
                return AnySequence([])
            }
        }
    }
    
    public static func ==(a: ComputationalMatrix<R>, b: ComputationalMatrix<R>) -> Bool {
        print(a.detailDescription, "?=", b.detailDescription)
        return a.toGrid == b.toGrid // TODO performance
    }
    
    public var description: String {
        return "CMatrix(\(align), \(align == .Rows ? rowTable.sum{ $0.1.count } : colTable.sum{ $0.1.count } ))"
    }
    
    public var detailDescription: String {
        switch align {
        case .Rows:
            return description + " [ " + rowTable.flatMap { (i, list) in
                list.map{ (j, a) in "\((i, j, a))"}
                }.joined(separator: ", ") + " ]"
        case .Cols:
            return description + " [ " + colTable.flatMap { (j, list) in
                list.map{ (i, a) in "\((i, j, a))"}
                }.joined(separator: ", ") + " ]"
        }
    }
}
