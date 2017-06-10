//
//  Matrix+Eigen.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

// To enable Eigen:
//
//   1. clone library by `git submodule update --init`
//   2. call `EigenAcceleration.enable(true)`
//

import Foundation

public extension IntegerNumber {
    public static var matrixImplType: _MatrixImpl<Int>.Type {
        return EigenAcceleration.enabled() ? _EigenIntMatrixImpl.self : _EucMatrixImpl<Int>.self
    }
}

public final class _EigenIntMatrixImpl: _MatrixImpl<IntegerNumber> {
    
    public required init(_ rows: Int, _ cols: Int, _ grid: [IntegerNumber]) {
        // TODO use _EigenIntMatrix instance.
        super.init(rows, cols, grid)
    }
    
    public override func eliminate<n: _Int, m: _Int>(mode: MatrixEliminationMode) -> MatrixElimination<IntegerNumber, n, m> {
        return MatrixElimination(self, mode, EucMatrixEliminationProcessor<IntegerNumber>.self)
    }
    
    public override func mul(_ b: _MatrixImpl<IntegerNumber>) -> _EigenIntMatrixImpl {
        assert(cols == b.rows, "Mismatching matrix size.")
        guard let b = b as? _EigenIntMatrixImpl else { fatalError() }
        
        // TODO impl instance method: EigenIntMatrix.mul
        
        var result = Array(repeating: 0, count: rows * b.cols)
        EigenIntMatrix.multiple(&result, rows, cols, b.cols, grid, b.grid)
        return _EigenIntMatrixImpl(rows, b.cols, result)
    }
}
