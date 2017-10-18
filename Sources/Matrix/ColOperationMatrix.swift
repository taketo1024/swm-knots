//
//  RowSortedMatrix.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/10/16.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct ColOperationMatrix<R: Ring>: CustomStringConvertible {
    public let rows: Int
    public let cols: Int
    
    internal var colTable: [Int: [(row: Int, value: R)]]
    
    public subscript(i: Int, j: Int) -> R {
        return colTable[j]?.first{ $0.row == i }?.value ?? 0 // TODO use binary search
    }
    
    public init<n, m>(_ a: Matrix<R, n, m>) {
        self.init(a.rows, a.cols, a.grid)
    }
    
    public init(_ rows: Int, _ cols: Int, _ grid: [R]) {
        self.rows = rows
        self.cols = cols
        self.colTable = [:]
        
        for (k, a) in grid.enumerated() {
            if a == 0 {
                continue
            }
            let i = k / cols
            let j = k % cols
            
            if colTable[j] == nil {
                colTable[j] = []
            }
            
            colTable[j]!.append( (i, a) )
        }
        
        sort()
    }
    
    public init(_ r: RowOperationMatrix<R>) {
        self.rows = r.rows
        self.cols = r.cols
        self.colTable = [:]
        
        for (i, list) in r.rowTable {
            for (j, a) in list {
                if colTable[j] == nil {
                    colTable[j] = []
                }
                colTable[j]!.append( (i, a) )
            }
        }
        
        sort()
    }
    
    internal mutating func sort() {
        for (j, list) in colTable {
            colTable[j] = list.sorted{ (e1, e2) in e1.row < e2.row }
        }
    }
    
    public var toGrid: [R] {
        var grid = Array(repeating: R.zero, count: rows * cols)
        for (j, list) in colTable {
            for (i, a) in list {
                grid[i * cols + j] = a
            }
        }
        return grid
    }
    
    public var isDiagonal: Bool {
        return colTable.forAll { (j, list) in (list.count == 1) && list.first!.row == j }
    }
    
    public var diagonal: [R] {
        return (0 ..< colTable.count).map{ j in colTable[j]!.first!.value }
    }
    
    public mutating func multiplyCol(at j0: Int, by r: R) {
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
    
    public mutating func addCol(at j0: Int, to j1: Int, multipliedBy r: R) {
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
    
    public mutating func swapCols(_ j0: Int, _ j1: Int) {
        let r0 = colTable[j0]
        colTable[j0] = colTable[j1]
        colTable[j1] = r0
    }
    
    public func elements(row i0: Int, after j0: Int) -> [(col: Int, value: R)] {
        return (j0 ..< cols).flatMap{ j in colTable[j]?.first.flatMap{ (i, a) in i == i0 ? Optional( (j, a) ) : nil } }
    }
    
    public var description: String {
        return colTable.map { e in
            "\(e.key): [" + e.value.map{ (j, a) in "\(j): \(a)"}.joined(separator: ", ") + "]"
        }.joined(separator: "\n")
    }
}
