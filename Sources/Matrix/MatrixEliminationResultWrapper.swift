//
//  MatrixEliminationResultWrapper.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct MatrixEliminationResultWrapper<n: _Int, m: _Int, R: EuclideanRing> {
    private let res: MatrixEliminationResult<R>
    
    public init<n, m>(_ matrix: Matrix<n, m, R>, _ res: MatrixEliminationResult<R>) {
        self.res = res
    }
    
    public var result: Matrix<n, m, R> {
        return res.result.asMatrix()
    }
    
    public var diagonal: [R] {
        return res.diagonal
    }
    
    public var rank: Int {
        return res.rank
    }
    
    public var left: Matrix<n, n, R> {
        return res.left.asMatrix()
    }
    
    public var leftInverse: Matrix<n, n, R> {
        return res.leftInverse.asMatrix()
    }
    
    public var right: Matrix<m, m, R> {
        return res.right.asMatrix()
    }
    
    public var rightInverse: Matrix<m, m, R> {
        return res.rightInverse.asMatrix()
    }
}

public extension MatrixEliminationResultWrapper where n == m {
    public var inverse: Matrix<n, n, R>? {
        return res.inverse?.asMatrix()
    }
     
    public var determinant: R {
        return res.determinant
    }
}
