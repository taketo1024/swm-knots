//
//  MatrixEliminator.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/09.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public enum MatrixEliminationMode {
    case Both
    case Rows
    case Cols
}

public class MatrixEliminator<R: Ring, n: _Int, m: _Int> {
    let mode: MatrixEliminationMode
    let rows: Int
    let cols: Int
    
    public var result: Matrix<R, n, m>
    var process: [EliminationStep<R>]
    
    private(set) var itr = 0
    
    var debug: Bool = false
    
    public required init(_ target: Matrix<R, n, m>, _ mode: MatrixEliminationMode, _ debug: Bool = false) {
        self.mode = mode
        self.rows = target.rows
        self.cols = target.cols
        
        self.result = target
        self.process = []
        self.debug = debug
        
        self.run()
    }
    
    public lazy var left: Matrix<R, n, n> = { [unowned self] in
        var Q = result.leftIdentity
        
        process
            .filter{ $0.isRowOperation }
            .forEach { $0.apply(to: &Q) }
        
        return Q
    }()
    
    public lazy var leftInverse: Matrix<R, n, n> = { [unowned self] in
        var Q = result.leftIdentity
        
        process
            .filter{ $0.isRowOperation }
            .reversed()
            .forEach{ $0.inverse.apply(to: &Q) }
        
        return Q
    }()
    
    public lazy var right: Matrix<R, m, m> = { [unowned self] in
        var P = result.rightIdentity
        
        process
            .filter{ $0.isColOperation }
            .forEach { $0.apply(to: &P) }
        
        return P
    }()
    
    public lazy var rightInverse: Matrix<R, m, m> = { [unowned self] in
        var P = result.rightIdentity
        
        process
            .filter{ $0.isColOperation }
            .reversed()
            .forEach{ $0.inverse.apply(to: &P) }
        
        return P
    }()
    
    public lazy var diagonal: [R] = { [unowned self] in
        let A = result
        let r = min(A.rows, A.cols)
        return (0 ..< r).map{ A[$0, $0] }
    }()
    
    final func run() {
        log("-----Start (mode: \(mode))-----\n\n\(result.detailDescription)\n")
        
        while !iteration() {
            itr += 1
        }
        
        log("-----Done (\(process.count) steps)-----\n\nResult:\n\(result.detailDescription)\n")
    }
    
    func iteration() -> Bool {
        fatalError("override in subclass")
    }
    
    final func apply(_ s: EliminationStep<R>) {
        s.apply(to: &result)
        process.append(s)
        
        log("\(itr): \(s) \n\n\(result.detailDescription)\n")
    }
    
    internal func log(_ msg: @autoclosure () -> String) {
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
    
    func apply<n, m>(to A: inout RowOperationMatrix<R, n, m>) {
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
}
