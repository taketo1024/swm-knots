//
//  Matrix+Eigen.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

// To enable Eigen,
//   1. `git submodule update --init`
//   2. add `USE_EIGEN=1` to Preprocessor Macros.
//   3. add `-DUSE_EIGEN` to Other Swift Compiler Flags.

import Foundation

#if USE_EIGEN
    
    public extension IntegerNumber {
        public static var matrixImplType: _MatrixImpl<Int>.Type {
            return _IntMatrixImpl.self
        }
    }
    
    public final class _IntMatrixImpl: _MatrixImpl<IntegerNumber> {
        
        private let ins: _EigenIntMatrix
        
        public required init(_ rows: Int, _ cols: Int, _ grid: [IntegerNumber]) {
            self.ins = _EigenIntMatrix(rows: rows, cols: cols, grid: grid)
            super.init(rows, cols, [])
        }
        
        public required init(_ rows: Int, _ cols: Int, _ ins: _EigenIntMatrix) {
            self.ins = ins
            super.init(rows, cols, [])
        }
        
        public override func eliminate<n: _Int, m: _Int>(mode: MatrixEliminationMode) -> MatrixElimination<IntegerNumber, n, m> {
            return MatrixElimination(self, mode, EucMatrixEliminationProcessor<IntegerNumber>.self)
        }
        
        public override func mul(_ b: _MatrixImpl<IntegerNumber>) -> _IntMatrixImpl {
            assert(cols == b.rows, "Mismatching matrix size.")
            guard let b = b as? _IntMatrixImpl else { fatalError() }
            
            let ins = self.ins.mul(b.ins)
            return _IntMatrixImpl(rows, b.cols, ins)
        }
    }
    
#endif

