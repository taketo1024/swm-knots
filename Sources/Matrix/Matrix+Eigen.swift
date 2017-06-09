//
//  Matrix+Eigen.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// MEMO: Polymorphism by protocol-extension doesn't work for operations... bug?
// Would better write:
//
//     public extension _Matrix where R == IntegerNumber {
//
// instead of:
//
//     public extension Matrix where R == IntegerNumber {

#if USE_EIGEN
    
    public extension Matrix where R == IntegerNumber {
        public static func * <ResultCols: _Int>(_ a: Matrix<R, Rows, Cols>, _ b: Matrix<R, Cols, ResultCols>) -> Matrix<R, Rows, ResultCols> {
            assert(a.cols == b.rows, "Mismatching matrix size.")
            var result = Array(repeating: 0, count: a.rows * b.cols)
            EigenLib.multiple(&result, a.rows, a.cols, b.cols, a.grid, b.grid)
            return Matrix<R, Rows, ResultCols>(rows: a.rows, cols: b.cols, grid: result)
        }
    }
    
#endif

