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
    public static func matrixEliminatiorType<n, m>() -> MatrixEliminator<Self, n, m>.Type? {
        return nil
    }
}

// EuclideanRing

public extension EuclideanRing {
    public static func matrixEliminatiorType<n, m>() -> MatrixEliminator<Self, n, m>.Type? {
        return EucMatrixEliminator<Self, n, m>.self
    }
}

// Field

/*
public extension Field {
    public static func matrixEliminatiorType<n, m>() -> MatrixEliminator<Self, n, m>.Type? {
        return FieldMatrixEliminator<Self, n, m>.self
    }
}
*/
