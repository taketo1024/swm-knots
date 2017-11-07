//
//  MatrixEliminator.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/09.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public enum MatrixForm {
    case Default
    case RowEchelon
    case ColEchelon
    case RowHermite
    case ColHermite
    case Diagonal
    case Smith
}

public class MatrixEliminator<R: EuclideanRing>: CustomStringConvertible {
    internal enum MatrixEliminationStep {
        case AddRow(at: Int, to: Int, mul: R)
        case MulRow(at: Int, by: R)
        case SwapRows(Int, Int)
        case AddCol(at: Int, to: Int, mul: R)
        case MulCol(at: Int, by: R)
        case SwapCols(Int, Int)
        
        var isRowOperation: Bool {
            switch self {
            case .AddRow, .MulRow, .SwapRows: return true
            default: return false
            }
        }
        
        var isColOperation: Bool {
            switch self {
            case .AddCol, .MulCol, .SwapCols: return true
            default: return false
            }
        }
        
        var determinant: R {
            switch self {
            case .AddRow(_, _, _), .AddCol(_, _, _):
                return R.identity
            case let .MulRow(at: _, by: r):
                return r
            case let .MulCol(at: _, by: r):
                return r
            case .SwapRows(_, _), .SwapCols(_, _):
                return -R.identity
            }
        }
        
        var inverse: MatrixEliminationStep {
            switch self {
            case let .AddRow(i, j, r):
                return .AddRow(at: i, to: j, mul: -r)
            case let .AddCol(i, j, r):
                return .AddCol(at: i, to: j, mul: -r)
            case let .MulRow(at: i, by: r):
                return .MulRow(at: i, by: r.inverse!)
            case let .MulCol(at: i, by: r):
                return .MulCol(at: i, by: r.inverse!)
            case .SwapRows(_, _), .SwapCols(_, _):
                return self
            }
        }
        
        internal var transpose: MatrixEliminationStep {
            switch self {
            case let .AddRow(i, j, r):
                return .AddCol(at: i, to: j, mul: r)
            case let .AddCol(i, j, r):
                return .AddRow(at: i, to: j, mul: r)
            case let .MulRow(at: i, by: r):
                return .MulCol(at: i, by: r)
            case let .MulCol(at: i, by: r):
                return .MulRow(at: i, by: r)
            case let .SwapRows(i, j):
                return .SwapCols(i, j)
            case let .SwapCols(i, j):
                return .SwapRows(i, j)
            }
        }
        
        internal func apply(to A: ComputationalMatrix<R>) {
            switch self {
            case let .AddRow(i, j, r):
                A.addRow(at: i, to: j, multipliedBy: r)
            case let .AddCol(i, j, r):
                A.addCol(at: i, to: j, multipliedBy: r)
            case let .MulRow(i, r):
                A.multiplyRow(at: i, by: r)
            case let .MulCol(i, r):
                A.multiplyCol(at: i, by: r)
            case let .SwapRows(i, j):
                A.swapRows(i, j)
            case let .SwapCols(i, j):
                A.swapCols(i, j)
            }
        }
    }

    internal var target: ComputationalMatrix<R>
    internal var process: [MatrixEliminationStep]
    internal var debug: Bool
    
    public convenience init<n, m>(_ target: Matrix<n, m, R>, debug: Bool = false) {
        self.init(ComputationalMatrix(target), debug: debug)
    }
    
    public required init(_ target: ComputationalMatrix<R>, debug: Bool = false) {
        self.target = target
        self.process = []
        self.debug = debug
    }
    
    public var rows: Int {
        return target.rows
    }
    
    public var cols: Int {
        return target.cols
    }

    public var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, process, .Default)
    }
    
    @discardableResult
    public final func run() -> MatrixEliminationResult<R> {
        log("-----Start:\(self)-----")
        
        prepare()
        while !iteration() {}
        finish()
        
        log("-----Done:\(self), \(process.count) steps)-----")
        
        return result
    }
    
    internal func prepare() {
        // override in subclass
    }
    
    internal func iteration() -> Bool {
        fatalError("override in subclass")
    }
    
    internal func finish() {
        // override in subclass
    }
    
    internal func run(_ eliminator: MatrixEliminator.Type) {
        let e = eliminator.init(target, debug: debug)
        e.run()
        process += e.process
    }
    
    internal func runTranpose(_ eliminator: MatrixEliminator.Type) {
        transpose()
        let e = eliminator.init(target, debug: debug)
        e.run()
        process += e.process.map{ s in s.transpose }
        transpose()
    }
    
    @_specialize(where R == IntegerNumber)
    internal func findMin(_ sequence: [(Int, R)]) -> (Int, R)? {
        var cand: (Int, R)? = nil
        for (i, a) in sequence {
            if a.isInvertible {
                return (i, a)
            }
            if cand == nil || a.degree < cand!.1.degree {
                cand = (i, a)
            }
        }
        return cand
    }
    
    internal func apply(_ s: MatrixEliminationStep) {
        s.apply(to: target)
        process.append(s)
        log("\(process.count): \(s)")
    }
    
    func transpose() {
        target.transpose()
        log("\(process.count): Transpose")
    }
    
    func log(_ msg: @autoclosure () -> String) {
        if debug {
            print(msg())
            if rows < 100 && cols < 100 {
                print()
                print(target.asMatrix.detailDescription)
                print()
            }
        }
    }
    
    public var description: String {
        return "\(type(of: self))"
    }
}

public final class RowEchelonEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    internal var targetRow = 0
    internal var targetCol = 0
    
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, process, .RowEchelon)
    }
    
    override func prepare() {
         target.switchAlignment(.Rows)
    }
    
    @_specialize(where R == IntegerNumber)
    override func iteration() -> Bool {
        if targetRow >= rows || targetCol >= cols {
            return true
        }
        
        // pivot element
        let col = target.enumerate(col: targetCol, fromRow: targetRow, headsOnly: true)
        guard let (i0, a0) = findMin(col) else {
            targetCol += 1
            return false
        }
        
        // eliminate target col
        for (i, a) in col {
            if i == i0 {
                continue
            }
            
            let (q, r) = a /% a0
            apply(.AddRow(at: i0, to: i, mul: -q))
            
            if r != 0 {
                return false
            }
        }
        
        // final step
        if a0.normalizeUnit != R.identity {
            apply(.MulRow(at: i0, by: a0.normalizeUnit))
        }
        
        if i0 != targetRow {
            apply(.SwapRows(i0, targetRow))
        }
        
        targetRow += 1
        targetCol += 1
        
        return false
    }
}

public final class ColEchelonEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, process, .ColEchelon)
    }
    
    internal override func iteration() -> Bool {
        runTranpose(RowEchelonEliminator.self)
        return true
    }
}

public final class RowHermiteEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    internal var targetRow = 0
    internal var targetCol = 0
    
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, process, .RowHermite)
    }
    
    override func prepare() {
        run(RowEchelonEliminator.self)
    }
    
    @_specialize(where R == IntegerNumber)
    internal override func iteration() -> Bool {
        if targetRow >= rows || targetCol >= cols {
            return true
        }
        
        let col = Array(target.enumerate(col: targetCol))
        guard let (i0, a0) = col.last, i0 >= targetRow else {
            targetCol += 1
            return false
        }
        
        for (i, a) in col {
            if i == i0 {
                break
            }
            
            let q = a / a0
            apply(.AddRow(at: i0, to: i, mul: -q))
        }
        
        targetRow += 1
        targetCol += 1
        return false
    }
}

public final class ColHermiteEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, process, .ColHermite)
    }
    
    internal override func iteration() -> Bool {
        runTranpose(RowHermiteEliminator.self)
        return true
    }
}

public final class DiagonalEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, process, .Diagonal)
    }
    
    override func iteration() -> Bool {
        if target.isDiagonal {
            return true
        }
        
        run(RowHermiteEliminator.self)
        
        if target.isDiagonal {
            return true
        }
        
        run(ColHermiteEliminator.self)
        
        return false
    }
}

public final class SmithEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    internal var targetIndex = 0
    
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, process, .Smith)
    }
    
    override func prepare() {
        run(DiagonalEliminator.self)
    }
    
    @_specialize(where R == IntegerNumber)
    internal override func iteration() -> Bool {
        if R.isField || targetIndex >= target.table.count {
            return true
        }
        
        let diagonal = targetDiagonal()
        guard let (i0, a0) = findMin(diagonal) else {
            return true
        }
        
        if !a0.isInvertible {
            for (i, a) in diagonal {
                if i == i0 {
                    continue
                }
                
                if a % a0 != R.zero {
                    diagonalGCD((i0, a0), (i, a))
                    return false
                }
            }
        }
        
        // now `a0` divides all other elements.
        if a0.normalizeUnit != 1 {
            apply(.MulRow(at: i0, by: a0.normalizeUnit))
        }
        
        if i0 != targetIndex {
            swapDiagonal(i0, targetIndex)
        }
        
        targetIndex += 1
        return false

    }
    
    private func diagonalGCD(_ d1: (Int, R), _ d2: (Int, R)) {
        let (i, a) = d1
        let (j, b) = d2
        let (p, q, r) = bezout(a, b)
        
        // r = gcd(a, b) = pa + qb
        // m = lcm(a, b) = -a * b / r
        
        apply(.AddRow(at: i, to: j, mul: p))     // [a, 0; pa, b]
        apply(.AddCol(at: j, to: i, mul: q))     // [a, 0;  r, b]
        apply(.AddRow(at: j, to: i, mul: -a/r))  // [0, m; r, b]
        apply(.AddCol(at: i, to: j, mul: -b/r))  // [0, m; r, 0]
        apply(.SwapRows(i, j))                   // [r, 0; 0, m]
    }

    private func swapDiagonal(_ i0: Int, _ i1: Int) {
        apply(.SwapRows(i0, i1))
        apply(.SwapCols(i0, i1))
    }
    
    private func targetDiagonal() -> [(Int, R)] {
        return (targetIndex ..< target.table.keys.count).map{ target.table[$0]!.first! }
    }
}
