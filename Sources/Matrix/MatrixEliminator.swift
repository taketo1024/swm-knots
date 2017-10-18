//
//  MatrixEliminator.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/09.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class MatrixEliminator<R: Ring, n: _Int, m: _Int> {
    let rows: Int
    let cols: Int
    let type: MatrixType
    
    private(set) var process: [EliminationStep<R>]
    private(set) var itr = 0
    private(set) var debug: Bool
    
    public required init(_ target: Matrix<R, n, m>, _ debug: Bool = false) {
        self.rows = target.rows
        self.cols = target.cols
        self.type = target.type
        
        self.process = []
        self.debug = debug
    }
    
    public var result: Matrix<R, n, m> {
        fatalError("override in subclass")
    }
    
    public var diagonal: [R] {
        fatalError("override in subclass")
    }
    
    public var rank: Int {
        return diagonal.count
    }
    
    public lazy var left: Matrix<R, n, n> = { [unowned self] in
        var Q = RowOperationMatrix<R>.identity(rows)
        process.forEach { $0.apply(to: &Q) }
        return Matrix(rows: rows, cols: cols, type: type, grid: Q.toGrid)
    }()
    
    public lazy var leftInverse: Matrix<R, n, n> = { [unowned self] in
        var Q = RowOperationMatrix<R>.identity(rows)
        process.reversed().forEach { $0.inverse.apply(to: &Q) }
        return Matrix(rows: rows, cols: cols, type: type, grid: Q.toGrid)
    }()
    
    public lazy var right: Matrix<R, m, m> = { [unowned self] in
        var Q = ColOperationMatrix<R>.identity(cols)
        process.forEach { $0.apply(to: &Q) }
        return Matrix(rows: rows, cols: cols, type: type, grid: Q.toGrid)
    }()
    
    public lazy var rightInverse: Matrix<R, m, m> = { [unowned self] in
        var Q = ColOperationMatrix<R>.identity(cols)
        process.reversed().forEach { $0.inverse.apply(to: &Q) }
        return Matrix(rows: rows, cols: cols, type: type, grid: Q.toGrid)
    }()
    
    public func run() {
        log("-----Start-----\n\n\(current.detailDescription)\n")
        
        while !iteration() {
            itr += 1
        }
        
        log("-----Done (\(process.count) steps)-----\n\nResult:\n\(current.detailDescription)\n")
    }
    
    func iteration() -> Bool {
        fatalError("override in subclass")
    }
    
    func addProcess(_ s: EliminationStep<R>) {
        process.append(s)
        log("\(process.count): \(s) \n\n\( current.detailDescription )\n")
    }
    
    var current: Matrix<R, n, m> {
        fatalError("override in subclass")
    }
    
    func log(_ msg: @autoclosure () -> String) {
        if debug {
            print(msg())
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
    
    func apply<n, m>(to A: inout Matrix<R, n, m>) {
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
    
    func apply(to A: inout RowOperationMatrix<R>) {
        switch self {
        case let .AddRow(i, j, r):
            A.addRow(at: i, to: j, multipliedBy: r)
        case let .MulRow(i, r):
            A.multiplyRow(at: i, by: r)
        case let .SwapRows(i, j):
            A.swapRows(i, j)
        default:
            break
        }
    }
    
    func apply(to A: inout ColOperationMatrix<R>) {
        switch self {
        case let .AddCol(i, j, r):
            A.addCol(at: i, to: j, multipliedBy: r)
        case let .MulCol(i, r):
            A.multiplyCol(at: i, by: r)
        case let .SwapCols(i, j):
            A.swapCols(i, j)
        default:
            break
        }
    }
}
