//
//  RowSortedMatrix.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/10/16.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct RowOperationMatrix<R: Ring>: CustomStringConvertible {
    public let rows: Int
    public let cols: Int
    
    internal var rowTable: [Int: [(col: Int, value: R)]]
    
    public subscript(i: Int, j: Int) -> R {
        return rowTable[i]?.first{ $0.col == j }?.value ?? 0 // TODO use binary search
    }
    
    public init<n, m>(_ a: Matrix<R, n, m>) {
        self.init(a.rows, a.cols, a.grid)
    }
    
    public init(_ rows: Int, _ cols: Int, _ grid: [R]) {
        self.rows = rows
        self.cols = cols
        self.rowTable = [:]
        
        for (k, a) in grid.enumerated() {
            if a == 0 {
                continue
            }
            let i = k / cols
            let j = k % cols
            
            if rowTable[i] == nil {
                rowTable[i] = []
            }
            
            rowTable[i]!.append( (j, a) )
        }
    }
    
    public init(_ r: ColOperationMatrix<R>) {
        self.rows = r.rows
        self.cols = r.cols
        self.rowTable = [:]
        
        for (j, list) in r.colTable {
            for (i, a) in list {
                if rowTable[i] == nil {
                    rowTable[i] = []
                }
                rowTable[i]!.append( (j, a) )
            }
        }
        
        sort()
    }
    
    internal mutating func sort() {
        for (i, list) in rowTable {
            rowTable[i] = list.sorted{ (e1, e2) in e1.col < e2.col }
        }
    }
    
    public var toGrid: [R] {
        var grid = Array(repeating: R.zero, count: rows * cols)
        for (i, list) in rowTable {
            for (j, a) in list {
                grid[i * cols + j] = a
            }
        }
        return grid
    }
    
    public var isDiagonal: Bool {
        return rowTable.forAll { (i, list) in (list.count == 1) && list.first!.col == i }
    }
    
    public var diagonal: [R] {
        return (0 ..< rowTable.count).map{ i in rowTable[i]!.first!.value }
    }
    
    public mutating func multiplyRow(at i0: Int, by r: R) {
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
    
    public mutating func addRow(at i0: Int, to i1: Int, multipliedBy r: R) {
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
    
    public mutating func swapRows(_ i0: Int, _ i1: Int) {
        let r0 = rowTable[i0]
        rowTable[i0] = rowTable[i1]
        rowTable[i1] = r0
    }
    
    public func elements(below i0: Int, col j0: Int) -> [(row: Int, value: R)] {
        return (i0 ..< rows).flatMap{ i in rowTable[i]?.first.flatMap{ (j, a) in j == j0 ? Optional( (i, a) ) : nil } }
    }
    
    public var description: String {
        return rowTable.map { e in
            "\(e.key): [" + e.value.map{ (j, a) in "\(j): \(a)"}.joined(separator: ", ") + "]"
        }.joined(separator: "\n")
    }
}
