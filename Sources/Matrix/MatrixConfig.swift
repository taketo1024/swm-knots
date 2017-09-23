//
//  DefaultMatrixImpl.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// General Ring

public extension Ring {
    public static func matrixImplType(_ type: MatrixType) -> _MatrixImpl<Self>.Type {
        return _GridMatrixImpl<Self>.self
    }
    
    public static func matrixEliminatiorType() -> MatrixEliminator<Self>.Type? {
        return nil
    }
}

// EuclideanRing

public extension EuclideanRing {
    public static func matrixEliminatiorType() -> MatrixEliminator<Self>.Type? {
        return EucMatrixEliminator<Self>.self
    }
}

// Field

public extension Field {
    public static func matrixEliminatiorType() -> MatrixEliminator<Self>.Type? {
        return FieldMatrixEliminator<Self>.self
    }
}

// Integer

public extension IntegerNumber {
    public static func matrixImplType(_ type: MatrixType) -> _MatrixImpl<IntegerNumber>.Type {
        return EigenAcceleration.enabled() ? _EigenIntMatrixImpl.self : _GridMatrixImpl<IntegerNumber>.self
    }
}
