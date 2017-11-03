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
    public static func matrixEliminatiorType<n, m>() -> MatrixEliminator<n, m, Self>.Type? {
        return nil
    }
}

// EuclideanRing

public extension EuclideanRing {
    public static func matrixEliminatiorType<n, m>() -> MatrixEliminator<n, m, Self>.Type? {
        return EucMatrixEliminator<n, m, Self>.self
    }
}

// Field

public extension Field {
    public static func matrixEliminatiorType<n, m>() -> MatrixEliminator<n, m, Self>.Type? {
        return FieldMatrixEliminator<n, m, Self>.self
    }
}

