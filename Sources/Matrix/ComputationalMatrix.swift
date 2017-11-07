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
    public var rows: Int
    public var cols: Int
    
    internal var align: ComputationalMatrixAlignment
    
    // align: .Rows  ->  [row : [(col, value)]]
    // align: .Cols  ->  [col : [(row, value)]]
    internal var table:  [Int : [(Int, R)]]

    public subscript(i: Int, j: Int) -> R {
        print("[warn] subscript on ComputationalMatrix is slow.")
        let (p, q) = (align == .Rows) ? (i, j) : (j, i)
        return table[p]?.first{ $0.0 == q }?.1 ?? 0
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
        self.table = [:]
        
        for (i, j, a) in components {
            if a == R.zero {
                continue
            }
            (align == .Rows) ? set(i, j, a) : set(j, i, a)
        }
        sort()
    }
    
    internal func set(_ i: Int, _ j: Int, _ a: R) {
        assert(a != R.zero)
        
        if table[i] == nil {
            table[i] = []
        }
        table[i]!.append( (j, a) )
    }

    internal func sort() {
        for (i, list) in table {
            table[i] = list.sorted{ (e1, e2) in e1.0 < e2.0 }
        }
    }
    
    public func switchAlignment(_ align: ComputationalMatrixAlignment) {
        if self.align == align {
            return
        }
        
        self.align = align
        
        let copy = table
        self.table = [:]
        
        for (i, list) in copy {
            for (j, a) in list {
                set(j, i, a)
            }
        }
        
        sort()
    }
    
    public func transpose() {
        (rows, cols) = (cols, rows)
        align = (align == .Rows) ? .Cols : .Rows
    }
    
    public var isDiagonal: Bool {
        return table.forAll { (i, list) in (list.count == 1) && list.first!.0 == i }
    }
    
    public var diagonal: [R] {
        return table.keys.sorted().flatMap { i -> R? in
            table[i]!.first.flatMap{ (j, a) -> R? in (i == j) ? a : nil }
        }
    }
    
    public static func *(a: ComputationalMatrix<R>, b: ComputationalMatrix<R>) -> ComputationalMatrix<R> {
        assert(a.rows == b.cols)
        
        let result = ComputationalMatrix<R>(rows: a.rows, cols: b.cols, components: [])
        
        // TODO support .Cols
        
        a.switchAlignment(.Rows)
        b.switchAlignment(.Rows)
        
        for (i, list) in a.table {
            var row: [Int: R] = [:]
            
            for (j, a) in list {
                if let bRow = b.table[j] {
                    for (k, b) in bRow {
                        row[k] = row[k, default: R.zero] + a * b
                    }
                }
            }
            
            row.lazy.filter{ (_, a) in a != R.zero }.forEach{ (j, a) in
                result.set(i, j, a)
            }
        }
        
        return result
    }
    
    public func multiplyRow(at i0: Int, by r: R) {
        switchAlignment(.Rows)
        
        guard var row = table[i0] else {
            return
        }
        
        let n = row.count
        var p = UnsafeMutablePointer(&row)
        
        for _ in 0 ..< n {
            let (j, a) = p.pointee
            p.pointee = (j, r * a)
            p += 1
        }
        
        row = row.filter{ $0.1 != R.zero }
        
        if row.count == 0 {
            table.removeValue(forKey: i0)
        } else {
            table[i0] = row
        }
    }
    
    public func addRow(at i0: Int, to i1: Int, multipliedBy r: R = R.identity) {
        switchAlignment(.Rows)
        
        guard let r0 = table[i0] else {
            return
        }
        
        guard let r1 = table[i1] else {
            table[i1] = r0.map{ ($0.0, r * $0.1 )}
            return
        }
        
        var result: [(Int, R)] = []
        
        var (p0, p1) = (UnsafePointer(r0), UnsafePointer(r1))
        var (k0, k1) = (0, 0) // counters
        let (n0, n1) = (r0.count, r1.count)
        
        while k0 < n0 || k1 < n1 {
            let b = (k0 < n0 && k1 < n1)
            if b && (p0.pointee.0 == p1.pointee.0) {
                let j0 = p0.pointee.0
                let (a0, a1) = (p0.pointee.1, p1.pointee.1)
                let value = r * a0 + a1
                
                if value != 0 {
                    result.append( (j0, value) )
                }
                
                p0 += 1
                p1 += 1
                k0 += 1
                k1 += 1
                
            } else if (k1 >= n1) || (b && p0.pointee.0 < p1.pointee.0) {
                let j0 = p0.pointee.0
                let a0 = p0.pointee.1
                result.append( (j0, r * a0) )
                
                p0 += 1
                k0 += 1
                
            } else if (k0 >= n0) || (b && p0.pointee.0 > p1.pointee.0) {
                let j1 = p1.pointee.0
                let a1 = p1.pointee.1
                result.append( (j1, a1) )
                
                p1 += 1
                k1 += 1
                
            }
        }
        
        if result.count == 0 {
            table.removeValue(forKey: i1)
        } else {
            table[i1] = result
        }
    }
    
    public func swapRows(_ i0: Int, _ i1: Int) {
        switchAlignment(.Rows)
        
        let r0 = table[i0]
        table[i0] = table[i1]
        table[i1] = r0
    }
    
    public func multiplyCol(at j0: Int, by r: R) {
        transpose()
        multiplyRow(at: j0, by: r)
        transpose()
    }
    
    public func addCol(at j0: Int, to j1: Int, multipliedBy r: R = R.identity) {
        transpose()
        addRow(at: j0, to: j1, multipliedBy: r)
        transpose()
    }
    
    public func swapCols(_ j0: Int, _ j1: Int) {
        transpose()
        swapRows(j0, j1)
        transpose()
    }
    
    public func enumerate(row i0: Int, fromCol j0: Int = 0) -> AnySequence<(Int, R)> {
        switch align {
        case .Rows:
            if let row = table[i0] {
                return AnySequence(row.lazy.filter{ (col, _) in col >= j0})
            } else {
                return AnySequence([])
            }
        case .Cols:
            return AnySequence((j0 ..< cols).lazy.flatMap{ j -> (Int, R)? in
                guard let col = self.table[j] else {
                    return nil
                }
                for (i, a) in col {
                    if i == i0 {
                        return (j, a)
                    } else if i > i0 {
                        return nil
                    }
                }
                return nil
            })
        }
    }
    
    public func enumerate(col j0: Int, fromRow i0: Int = 0) -> AnySequence<(Int, R)> {
        transpose()
        let result = enumerate(row: j0, fromCol: i0)
        transpose()
        return result
    }
    
    public static func identity(_ n: Int, align: ComputationalMatrixAlignment = .Rows) -> ComputationalMatrix<R> {
        let components = (0 ..< n).map{ i in MatrixComponent(i, i, R.identity)}
        return ComputationalMatrix(rows: n, cols: n, components: components, align: align)
    }
    
    public static func ==(a: ComputationalMatrix<R>, b: ComputationalMatrix<R>) -> Bool {
        if (a.rows, a.cols) != (b.rows, b.cols) {
            return false
        }
        
        if a.align != b.align {
            b.switchAlignment(a.align)
        }
        
        // wish we could just write `a.table == b.table` ..
        
        return (a.table.keys == b.table.keys) && a.table.keys.forAll{ i in
            let (x, y) = (a.table[i]!, b.table[i]!)
            if x.count != y.count {
                return false
            }
            return (0 ..< x.count).forAll { i in x[i] == y[i] }
        }
    }
    
    public func generateGrid() -> [R] {
        var grid = Array(repeating: R.zero, count: rows * cols)
        switch align {
        case .Rows:
            for (i, list) in table {
                for (j, a) in list {
                    grid[i * cols + j] = a
                }
            }
        case .Cols:
            for (j, list) in table {
                for (i, a) in list {
                    grid[i * cols + j] = a
                }
            }
        }
        return grid
    }
    
    public var description: String {
        return "CMatrix(\(align), \(align == .Rows ? table.sum{ $0.1.count } : table.sum{ $0.1.count } ))"
    }
    
    public var detailDescription: String {
        return description + " [ " + table.flatMap { (i, list) in
            list.map{ (j, a) in "\( align == .Rows ? (i, j, a) : (j, i, a) )"}
            }.joined(separator: ", ") + " ]"
    }
}
