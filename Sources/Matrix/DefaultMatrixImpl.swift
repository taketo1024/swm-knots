//
//  DefaultMatrixImpl.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// General Rings

public extension Ring {
    public static func matrixImplType(_ type: MatrixType) -> _MatrixImpl<Self>.Type {
        switch type {
        case .Default:
            return _GridMatrixImpl<Self>.self
        case .Sparse:
            return _SparseMatrixImpl<Self>.self
        }
    }
}

// EuclideanRings

public extension EuclideanRing {
    public static func matrixImplType(_ type: MatrixType) -> _MatrixImpl<Self>.Type {
        switch type {
        case .Default:
            return _EucMatrixImpl<Self>.self
        case .Sparse:
            return _SparseMatrixImpl<Self>.self
        }
    }
}

public final class _EucMatrixImpl<R: EuclideanRing>: _SparseMatrixImpl<R> {
    public override func eliminate<n: _Int, m: _Int>(mode: MatrixEliminationMode) -> MatrixElimination<R, n, m> {
        return MatrixElimination(self, mode, EucMatrixEliminationProcessor<R>.self)
    }
    
    public override func determinant() -> R {
        let e: MatrixElimination<R, Dynamic, Dynamic> = self.eliminate(mode: .Both)
        return e.determinant
    }
}

// Fields

public extension Field {
    public static func matrixImplType(_ type: MatrixType) -> _MatrixImpl<Self>.Type {
        switch type {
        case .Default:
            return _FieldMatrixImpl<Self>.self
        case .Sparse:
            return _SparseMatrixImpl<Self>.self
        }
    }
}

public final class _FieldMatrixImpl<K: Field>: _GridMatrixImpl<K> {
    public override func eliminate<n: _Int, m: _Int>(mode: MatrixEliminationMode) -> MatrixElimination<K, n, m> {
        return MatrixElimination(self, mode, FieldMatrixEliminationProcessor<K>.self)
    }
    
    public override func determinant() -> K {
        let e: MatrixElimination<K, Dynamic, Dynamic> = self.eliminate(mode: .Both)
        return e.determinant
    }
}
