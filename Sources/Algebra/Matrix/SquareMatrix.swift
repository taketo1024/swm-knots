//
//  SquareMatrix.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/17.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias SquareMatrix<n: _Int, R: Ring> = Matrix<n, n, R>

// TODO: conform to Ring after conditional conformance is supported.
public extension SquareMatrix where n == m {
    public static var identity: Matrix<n, n, R> {
        return Matrix<n, n, R> { $0 == $1 ? 1 : 0 }
    }
    
    public var trace: R {
        return (0 ..< rows).sum { i in self[i, i] }
    }
    
    public static func ** (a: Matrix<n, n, R>, k: Int) -> Matrix<n, n, R> {
        return k == 0 ? .identity : a * (a ** (k - 1))
    }
}

public extension SquareMatrix where n == m, R: EuclideanRing {
    public var determinant: R {
        return eliminate().determinant
    }
    
    public var isInvertible: Bool {
        return determinant.isInvertible
    }
    
    public var inverse: Matrix<n, n, R>? {
        return eliminate().inverse
    }
}

