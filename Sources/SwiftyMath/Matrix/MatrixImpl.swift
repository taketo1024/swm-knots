//
//  RowSortedMatrix.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/10/16.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

internal typealias ComputationSpecializedRing = 𝐙

// TODO to internal class

public final class MatrixImpl<R: Ring>: Hashable, CustomStringConvertible {
    public typealias Component = MatrixComponent<R>
    
    public enum Alignment: String, Codable {
        case Rows, Cols
    }
    
    public internal(set) var rows: Int
    public internal(set) var cols: Int
    
    internal var align: Alignment
    internal var table:  [Int : [(Int, R)]] // [row : [ (col, R) ]]
    
    internal var eliminationResult: AnyObject? = nil // TODO cache for each form?
    
    private init(_ rows: Int, _ cols: Int, _ align: Alignment, _ table: [Int : [(Int, R)]]) {
        self.rows = rows
        self.cols = cols
        self.align = align
        self.table = table
    }
    
    public convenience init(rows: Int, cols: Int, align: Alignment = .Rows, grid: [R]) {
        let components = grid.enumerated().compactMap{ (k, a) -> MatrixComponent<R>? in
            (a != .zero) ? MatrixComponent(k / cols, k % cols, a) : nil
        }
        self.init(rows: rows, cols: cols, align: align, components: components)
    }
    
    public convenience init(rows: Int, cols: Int, align: Alignment = .Rows, generator g: (Int, Int) -> R) {
        let components = (0 ..< rows).flatMap { i -> [Component] in
            (0 ..< cols).compactMap { j -> Component? in
                let a = g(i, j)
                return (a != .zero) ? Component(i, j, a) : nil
            }
        }
        self.init(rows: rows, cols: cols, align: align, components: components)
    }
    
    public convenience init<S: Sequence>(rows: Int, cols: Int, align: Alignment = .Rows, components: S) where S.Element == MatrixComponent<R> {
        self.init(rows, cols, align, [:])
        
        for c in components where c.value != .zero {
            let (i, j, a) = (c.row, c.col, c.value)
            (align == .Rows) ? set(i, j, a) : set(j, i, a)
        }
        sort()
    }
    
    public subscript(i: Int, j: Int) -> R {
        let (p, q) = (align == .Rows) ? (i, j) : (j, i)
        return table[p]?.binarySearch(q, { $0.0 })?.element.1 ?? .zero
    }
    
    internal func set(_ i: Int, _ j: Int, _ a: R) {
        if (align == .Rows) {
            assert(0 <= i && i < rows)
            assert(0 <= j && j < cols)
        } else {
            assert(0 <= i && i < cols)
            assert(0 <= j && j < rows)
        }
        assert(a != .zero)
        
        if table[i] == nil {
            table[i] = []
        }
        table[i]!.append( (j, a) )
    }

    @_specialize(where R == ComputationSpecializedRing)
    internal func sort() {
        for (i, list) in table {
            table[i] = list.sorted{ (e1, e2) in e1.0 < e2.0 }
        }
    }
    
    public func copy() -> MatrixImpl<R> {
        return MatrixImpl(rows, cols, align, table)
    }
    
    public func switchAlignment(_ align: Alignment) {
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
    
    public var density: Double {
        let c = table.sum{ (_, list) in list.count }
        return Double(c) / Double(rows * cols)
    }
    
    public var sparsity: Double {
        return 1.0 - density
    }
    
    public var isZero: Bool {
        return table.isEmpty
    }
    
    public var isDiagonal: Bool {
        return table.forAll { (i, list) in (list.count == 1) && list.first!.0 == i }
    }
    
    public var diagonal: [R] {
        return table.keys.sorted().compactMap { i -> R? in
            table[i]!.first.flatMap{ (j, a) -> R? in (i == j) ? a : nil }
        }
    }
    
    public static func zero(rows: Int, cols: Int, align: Alignment = .Rows) -> MatrixImpl<R> {
        return MatrixImpl(rows: rows, cols: cols, align: align, components: [])
    }
    
    public static func identity(_ n: Int, align: Alignment = .Rows) -> MatrixImpl<R> {
        let components = (0 ..< n).map{ i in MatrixComponent(i, i, R.identity)}
        return MatrixImpl(rows: n, cols: n, align: align, components: components)
    }
    
    public var components: [MatrixComponent<R>] {
        switchAlignment(.Rows)
        return table.flatMap{ (i, list) in list.map{(j, a) in MatrixComponent(i, j, a)} }
    }
    
    public func components(ofRow i: Int) -> [MatrixComponent<R>] {
        switchAlignment(.Rows)
        return table[i].map { $0.map{ (j, r) in MatrixComponent(i, j, r) } } ?? []
    }
    
    public func components(ofCol j: Int) -> [MatrixComponent<R>] {
        switchAlignment(.Cols)
        return table[j].map { $0.map{ (i, r) in MatrixComponent(i, j, r) } } ?? []
    }
    
    @discardableResult
    public func transpose() -> MatrixImpl<R> {
        (rows, cols) = (cols, rows)
        align = (align == .Rows) ? .Cols : .Rows
        return self
    }
    
    public var transposed: MatrixImpl<R> {
        return self.copy().transpose()
    }
    
    public func submatrix(rowRange: CountableRange<Int>) -> MatrixImpl<R> {
        return submatrix(rowRange, 0 ..< cols)
    }
    
    public func submatrix(colRange: CountableRange<Int>) -> MatrixImpl<R> {
        return submatrix(0 ..< rows, colRange)
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    public func submatrix(_ rowRange: CountableRange<Int>, _ colRange: CountableRange<Int>) -> MatrixImpl<R> {
        assert(0 <= rowRange.lowerBound && rowRange.upperBound <= rows)
        assert(0 <= colRange.lowerBound && colRange.upperBound <= cols)

        return submatrix({i in rowRange.contains(i)}, {j in colRange.contains(j)})
    }
    
    public func submatrix(_ rowCond: (Int) -> Bool, _ colCond: (Int) -> Bool) -> MatrixImpl<R> {
        let (sRows, sCols, iList, jList): (Int, Int, [Int], [Int])
        
        switch align {
        case .Rows:
            (iList, jList) = ((0 ..< rows).filter(rowCond), (0 ..< cols).filter(colCond))
            (sRows, sCols) = (iList.count, jList.count)
        case .Cols:
            (iList, jList) = ((0 ..< cols).filter(colCond), (0 ..< rows).filter(rowCond))
            (sRows, sCols) = (jList.count, iList.count)
        }
        
        let subTable = table.compactMap{ (i, list) -> (Int, [(Int, R)])? in
            guard let k = iList.binarySearch(i) else {
                return nil
            }
            let subList = list.compactMap{ (j, a) -> (Int, R)? in
                guard let l = jList.binarySearch(j) else {
                    return nil
                }
                return (l, a)
            }
            return !subList.isEmpty ? (k, subList) : nil
        }
        
        return MatrixImpl(sRows, sCols, align, Dictionary(pairs: subTable))
    }
    
    public func mapValues<R2>(_ f: (R) -> R2) -> MatrixImpl<R2> {
        typealias M = MatrixImpl<R2>
        let mapped = table.mapValues { $0.map{ ($0, f($1)) } }
        let a = (align == .Rows) ? M.Alignment.Rows : M.Alignment.Cols
        return M(rows, cols, a, mapped)
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    public static func ==(a: MatrixImpl, b: MatrixImpl) -> Bool {
        if (a.rows, a.cols) != (b.rows, b.cols) {
            return false
        }
        
        if a.align != b.align {
            b.switchAlignment(a.align)
        }
        
        // wish we could just write `a.table == b.table` ..
        
        return (Set(a.table.keys) == Set(b.table.keys)) && a.table.keys.forAll{ i in
            let (x, y) = (a.table[i]!, b.table[i]!)
            return x.elementsEqual(y) { $0 == $1 }
        }
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    public static func +(a: MatrixImpl, b: MatrixImpl) -> MatrixImpl<R> {
        return a // FIXME!
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    public static prefix func -(a: MatrixImpl) -> MatrixImpl<R> {
        return a.mapValues{ -$0 }
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    public static func *(r: R, a: MatrixImpl) -> MatrixImpl<R> {
        return a.mapValues{ r * $0 }
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    public static func *(a: MatrixImpl, r: R) -> MatrixImpl<R> {
        return a.mapValues{ $0 * r }
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    public static func *(a: MatrixImpl, b: MatrixImpl) -> MatrixImpl<R> {
        assert(a.cols == b.rows)
        
        let result = MatrixImpl<R>(rows: a.rows, cols: b.cols, components: [])
        
        // TODO support .Cols
        
        a.switchAlignment(.Rows)
        b.switchAlignment(.Rows)
        
        for (i, list) in a.table {
            var row: [Int: R] = [:]
            
            for (j, a) in list {
                if let bRow = b.table[j] {
                    for (k, b) in bRow {
                        row[k] = row[k, default: .zero] + a * b
                    }
                }
            }
            
            row.filter{ (_, a) in a != .zero }.forEach{ (j, a) in
                result.set(i, j, a)
            }
        }
        
        result.sort()
        return result
    }
    
    @_specialize(where R == ComputationSpecializedRing)
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
        
        row = row.filter{ $0.1 != .zero }
        
        if row.count == 0 {
            table.removeValue(forKey: i0)
        } else {
            table[i0] = row
        }
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    public func addRow(at i0: Int, to i1: Int, multipliedBy r: R = .identity) {
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
                
                if value != .zero {
                    result.append( (j0, value) )
                }
                
                p0 += 1
                p1 += 1
                k0 += 1
                k1 += 1
                
            } else if (k1 >= n1) || (b && p0.pointee.0 < p1.pointee.0) {
                let j0 = p0.pointee.0
                let a0 = p0.pointee.1
                let value = r * a0
                
                if value != .zero {
                    result.append( (j0, r * a0) )
                }
                
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
    
    public func addCol(at j0: Int, to j1: Int, multipliedBy r: R = .identity) {
        transpose()
        addRow(at: j0, to: j1, multipliedBy: r)
        transpose()
    }
    
    public func swapCols(_ j0: Int, _ j1: Int) {
        transpose()
        swapRows(j0, j1)
        transpose()
    }
    
    public func generateGrid() -> [R] {
        var grid = Array(repeating: R.zero, count: rows * cols)
        switch align {
        case .Rows:
            for (i, list) in table {
                for (j, a) in list {
                    if i * cols + j >= grid.count {
                        print(i, j)
                    }
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
    
    public var hashValue: Int {
        return 0 // TODO
    }
    
    public var description: String {
        return "CMatrix<\(rows), \(cols)> [ " + table.flatMap { (i, list) in
            list.map{ (j, a) in "\(a)" + Format.sub("\(align == .Rows ? (i, j) : (j, i) )") }
        }.joined(separator: ", ") + " ]"
    }
}

public extension MatrixImpl where R: EuclideanRing{
    public func eliminate(form: MatrixForm = .Diagonal) -> MatrixEliminationResult<R> {
        if let res = eliminationResult as? MatrixEliminationResult<R> {
            return res
        }
        
        let eliminator = { () -> MatrixEliminator<R> in
            switch form {
            case .RowEchelon: return RowEchelonEliminator(self)
            case .ColEchelon: return ColEchelonEliminator(self)
            case .RowHermite: return RowHermiteEliminator(self)
            case .ColHermite: return ColHermiteEliminator(self)
            case .Diagonal:   return DiagonalEliminator  (self)
            case .Smith:      return SmithEliminator     (self)
            default: fatalError()
            }
        }()
        
        let result = eliminator.run()
        eliminationResult = result
        return result
    }
}

extension MatrixImpl: Codable where R: Codable {
    enum CodingKeys: String, CodingKey {
        case rows, cols, grid, components
    }
    
    public convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rows = try c.decode(Int.self, forKey: .rows)
        let cols = try c.decode(Int.self, forKey: .cols)
        
        if c.contains(.grid) {
            let grid = try c.decode([R].self, forKey: .grid)
            self.init(rows: rows, cols: cols, align: .Rows, grid: grid)
        } else {
            let comps = try c.decode([MatrixComponent<R>].self, forKey: .components)
            self.init(rows: rows, cols: cols, align: .Rows, components: comps)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(rows, forKey: .rows)
        try c.encode(cols, forKey: .cols)
        if density > 0.5 {
            try c.encode(generateGrid(), forKey: .grid)
        } else {
            try c.encode(components, forKey: .components)
        }
    }
}

// TODO move to FreeModule.init
public extension MatrixImpl {
    public func generateElements<A>(from basis: [A]) -> [FreeModule<A, R>] {
        assert(basis.count <= rows)
        
        switchAlignment(.Cols)
        
        return (0 ..< cols).map { j -> FreeModule<A, R> in
            guard let v = table[j] else {
                return .zero
            }
            return FreeModule( v.map{ (i, r) in (basis[i], r)} )
        }
    }
}
