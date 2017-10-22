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
    var target: Matrix<R, n, m>
    var process: [EliminationStep<R>]
    
    private(set) var itr = 0
    private(set) var debug: Bool
    
    public required init(_ target: Matrix<R, n, m>, _ debug: Bool = false) {
        self.rows = target.rows
        self.cols = target.cols
        self.type = target.type
        self.target = target
        self.process = []
        self.debug = debug
    }
    
    public var result: Matrix<R, n, m> {
        return target
    }
    
    public lazy var diagonal: [R] = { [unowned self] in
        let r = min(target.rows, target.cols)
        return (0 ..< r).map{ target[$0, $0] }
    }()
    
    public var rank: Int {
        return diagonal.filter{ $0 != 0 }.count
    }
    
    public lazy var left: Matrix<R, n, n> = { [unowned self] in
        var Q = RowOperationMatrix<R>.identity(rows)
        process.forEach { $0.apply(to: &Q) }
        return Matrix(rows: rows, cols: rows, type: type, grid: Q.toGrid)
    }()
    
    public lazy var leftInverse: Matrix<R, n, n> = { [unowned self] in
        var Q = RowOperationMatrix<R>.identity(rows)
        process.reversed().forEach { $0.inverse.apply(to: &Q) }
        return Matrix(rows: rows, cols: rows, type: type, grid: Q.toGrid)
    }()
    
    public lazy var right: Matrix<R, m, m> = { [unowned self] in
        var Q = ColOperationMatrix<R>.identity(cols)
        process.forEach { $0.apply(to: &Q) }
        return Matrix(rows: cols, cols: cols, type: type, grid: Q.toGrid)
    }()
    
    public lazy var rightInverse: Matrix<R, m, m> = { [unowned self] in
        var Q = ColOperationMatrix<R>.identity(cols)
        process.reversed().forEach { $0.inverse.apply(to: &Q) }
        return Matrix(rows: cols, cols: cols, type: type, grid: Q.toGrid)
    }()
    
    public func run() {
        log("-----Start-----\n\n\(target.detailDescription)\n")
        
        while !iteration() {
            itr += 1
        }
        
        log("-----Done (\(process.count) steps)-----\n\nResult:\n\(target.detailDescription)\n")
    }
    
    func iteration() -> Bool {
        fatalError("override in subclass")
    }
    
    func apply(_ s: EliminationStep<R>) {
        s.apply(to: &target)
        process.append(s)
        log("\(process.count): \(s) \n\n\( target.detailDescription )\n")
    }
    
    func log(_ msg: @autoclosure () -> String) {
        if debug {
            print(msg())
        }
    }
}
