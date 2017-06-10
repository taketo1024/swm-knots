//
//  MatrixEliminationProcessor.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/09.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

internal class MatrixEliminationProcessor<R: Ring> {
    let mode: MatrixEliminationMode
    let rows: Int
    let cols: Int
    
    var result: _MatrixImpl<R>
    var process: [EliminationStep<R>]
    
    let maxItr: Int
    private(set) var itr = 0
    
    var debug: Bool = false
    
    required init(_ target: _MatrixImpl<R>, _ mode: MatrixEliminationMode, debug: Bool = false) {
        self.mode = mode
        self.rows = target.rows
        self.cols = target.cols
        
        self.result = target.copy()
        self.process = []
        
        self.maxItr = {
            switch mode {
            case .Both: return min(target.rows, target.cols)
            case .Rows: return target.rows
            case .Cols: return target.cols
            }
        }()
    }
    
    final func run() {
        log("-----Start (mode: \(mode))-----\n\n\(result.alignedDescription)\n")
        iterations()
        log("-----Done (\(process.count) steps)-----\n\nResult:\n\(result.alignedDescription)\n")
    }
    
    func iterations() {
        while itr < maxItr {
            if iteration() {
                itr += 1
            } else {
                break
            }
        }
    }
    
    func iteration() -> Bool {
        fatalError("override in subclass")
    }
    
    final func apply(_ s: EliminationStep<R>) {
        s.apply(to: result)
        process.append(s)
        
        log("\(itr)/\(maxItr): \(s) \n\n\(result.alignedDescription)\n")
    }
    
    final func indexIterator() -> AnySequence<(Int, Int)> {
        return AnySequence({ return EliminationIterator(self) })
    }
    
    private func log(_ msg: @autoclosure () -> String) {
        if debug {
            print(msg())
        }
    }
}

internal class EucMatrixEliminationProcessor<R: EuclideanRing>: MatrixEliminationProcessor<R> {
    override func iteration() -> Bool {
        let doRows = (mode != .Cols)
        let doCols = (mode != .Rows)
        
        guard var (i0, j0) = next() else {
            if mode == .Both { // The area left is O. Exit iteration.
                return false
            } else {           // The target row/col is O. Continue iteration.
                return true
            }
        }
        
        elimination: while true {
            if doRows && !eliminateRow(&i0, j0) {
                continue elimination
            }
            if doCols && !eliminateCol(i0, &j0) {
                continue elimination
            }
            
            if doRows && doCols && !result[i0, j0].isUnit {
                let a = result[i0, j0]
                for i in itr ..< rows {
                    for j in itr ..< cols {
                        if i == i0 || j == j0 || result[i, j] == 0 {
                            continue
                        }
                        
                        let b = result[i, j]
                        if b % a != 0 {
                            self.apply(.AddRow(at: i, to: i0, mul: 1))
                            continue elimination
                        }
                    }
                }
            }
            break elimination
        }
        
        // TODO maybe implement NumberType or Comparable
        if R.self == IntegerNumber.self && (result[i0, j0] as! IntegerNumber) < 0 {
            if doRows {
                self.apply(.MulRow(at: i0, by: -1))
            } else {
                self.apply(.MulCol(at: j0, by: -1))
            }
        }
        
        if doRows && i0 > itr {
            self.apply(.SwapRows(itr, i0))
        }
        
        if doCols && j0 > itr {
            self.apply(.SwapCols(itr, j0))
        }
        
        return true
    }
    
    private func next() -> (Int, Int)? {
        var min = R.zero
        var (i0, j0) = (0, 0)
        
        for (i, j) in indexIterator() {
            let a = result[i, j]
            
            if a.isUnit {
                return (i, j)
            }
            
            if a != 0 && (min == 0 || a.degree < min.degree) {
                min = a
                (i0, j0) = (i, j)
            }
        }
        
        if min != 0 {
            return (i0, j0)
        } else {
            return nil
        }
    }
    
    private func eliminateRow(_ i0: inout Int, _ j0: Int) -> Bool {
        let a = result[i0, j0]
        
        for i in itr ..< rows {
            if i == i0 || result[i, j0] == 0 {
                continue
            }
            
            let b = result[i, j0]
            let (q, r) = b /% a
            
            self.apply(.AddRow(at: i0, to: i, mul: -q))
            
            if r != 0 {
                i0 = i
                return false
            }
        }
        
        // at this point, it is guaranteed that result[i, j0] == 0 for (i >= itr, i != i0)
        
        if mode == .Rows {
            for i in 0 ..< itr {
                if i == i0 || result[i, j0] == 0 {
                    continue
                }
                
                let b = result[i, j0]
                let (q, _) = b /% a
                
                self.apply(.AddRow(at: i0, to: i, mul: -q))
            }
        }
        
        return true
    }
    
    private func eliminateCol(_ i0: Int, _ j0: inout Int) -> Bool {
        let a = result[i0, j0]
        
        for j in itr ..< cols {
            if j == j0 || result[i0, j] == 0 {
                continue
            }
            
            let b = result[i0, j]
            let (q, r) = b /% a
            
            self.apply(.AddCol(at: j0, to: j, mul: -q))
            
            if r != 0 {
                j0 = j
                return false
            }
        }
        
        // at this point, it is guaranteed that result[i0, j] == 0 for (j >= itr, j != j0)
        
        if mode == .Cols {
            for j in 0 ..< itr {
                if j == j0 || result[i0, j] == 0 {
                    continue
                }
                
                let b = result[i0, j]
                let (q, _) = b /% a
                
                self.apply(.AddCol(at: j0, to: j, mul: -q))
            }
        }
        
        return true
    }
}

internal class FieldMatrixEliminationProcessor<K: Field>: MatrixEliminationProcessor<K> {
    override func iteration() -> Bool {
        let doRows = (mode != .Cols)
        let doCols = (mode != .Rows)
        
        guard var (i0, j0) = next() else {
            if mode == .Both { // The area left is O. Exit iteration.
                return false
            } else {           // The target row/col is O. Continue iteration.
                return true
            }
        }
        
        if doRows && i0 > itr {
            self.apply(.SwapRows(itr, i0))
            i0 = itr
        }
        
        if doCols && j0 > itr {
            self.apply(.SwapCols(itr, j0))
            j0 = itr
        }
        
        if doRows {
            eliminateRow(i0, j0)
        }
        
        if doCols {
            eliminateCol(i0, j0)
        }
        
        return true
    }
    
    private func next() -> (row: Int, col: Int)? {
        for (i, j) in indexIterator() {
            let a = result[i, j]
            if a != 0 {
                return (i, j)
            }
        }
        return nil
    }
    
    private func eliminateRow(_ i0: Int, _ j0: Int) {
        let a = result[i0, j0]
        if a != K.identity {
            apply(.MulRow(at: i0, by: a.inverse!))
        }
        
        for i in 0 ..< rows {
            if i == i0 || result[i, j0] == 0 {
                continue
            }
            
            apply(.AddRow(at: i0, to: i, mul: -result[i, j0]))
        }
    }
    
    private func eliminateCol(_ i0: Int, _ j0: Int) {
        let a = result[i0, j0]
        if a != K.identity {
            apply(.MulCol(at: i0, by: a.inverse!))
        }
        
        for j in 0 ..< cols {
            if j == j0 || result[i0, j] == 0 {
                continue
            }
            
            apply(.AddCol(at: j0, to: j, mul: -result[i0, j]))
        }
    }
}

internal enum EliminationStep<R: Ring> {
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
    
    var inverse: EliminationStep<R> {
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
    
    func apply(to A: _MatrixImpl<R>) {
        switch self {
        case let .AddRow(i, j, r):
            A.addRow(at: i, to: j, multipliedBy: r)
        case let .MulRow(i, r):
            A.multiplyRow(at: i, by: r)
        case let .SwapRows(i, j):
            A.swapRows(i, j)
        case let .AddCol(i, j, r):
            A.addCol(at: i, to: j, multipliedBy: r)
        case let .MulCol(i, r):
            A.multiplyCol(at: i, by: r)
        case let .SwapCols(i, j):
            A.swapCols(i, j)
        }
    }
}

private struct EliminationIterator<R: Ring> : IteratorProtocol {
    typealias Element = (Int, Int)
    
    private weak var p: MatrixEliminationProcessor<R>!
    private var current: (Int, Int)
    
    init(_ processor: MatrixEliminationProcessor<R>) {
        self.p = processor
        self.current = (p.itr, p.itr)
    }
    
    mutating func next() -> (Int, Int)? {
        guard current.0 < p.rows && current.1 < p.cols else {
            return nil
        }
        
        defer {
            switch p.mode {
            case .Both:
                if current.0 + 1 >= p.rows {
                    current = (p.itr, current.1 + 1)
                } else {
                    current = (current.0 + 1, current.1)
                }
            case .Rows:
                current = (current.0 + 1, current.1)
            case .Cols:
                current = (current.0, current.1 + 1)
            }
        }
        
        return (current.0, current.1)
    }
}
