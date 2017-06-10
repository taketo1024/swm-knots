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
    public static func matrixImplType(_ type: MatrixType) -> _MatrixImpl<IntegerNumber>.Type {
        switch type {
        case .Default:
            return EigenAcceleration.enabled() ? _EigenIntMatrixImpl.self : _GridMatrixImpl<IntegerNumber>.self
        case .Sparse:
            return _SparseMatrixImpl<IntegerNumber>.self
        }
    }
}

// TODO do not inherit from _GridMatrixImpl.
// hold an instance of EigenIntMatrix.

public final class _EigenIntMatrixImpl: _GridMatrixImpl<IntegerNumber> {
    // TODO impl instance method: EigenIntMatrix.mul
    public override func mul(_ b: _MatrixImpl<IntegerNumber>) -> _EigenIntMatrixImpl {
        assert(cols == b.rows, "Mismatching matrix size.")
        guard let b = b as? _EigenIntMatrixImpl else { fatalError() }
        
        var result = Array(repeating: 0, count: rows * b.cols)
        EigenIntMatrix.multiple(&result, rows, cols, b.cols, grid, b.grid)
        return _EigenIntMatrixImpl(rows, b.cols, result)
    }
}
