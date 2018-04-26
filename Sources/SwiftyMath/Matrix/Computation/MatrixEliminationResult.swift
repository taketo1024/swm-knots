//
//  MatrixEliminationResult.swift
//  Sample
//
//  Created by Taketo Sano on 2018/04/26.
//

import Foundation

public struct MatrixEliminationResult<n: _Int, m: _Int, R: EuclideanRing> {
    private let res: MatrixEliminationResultImpl<R>
    
    internal init<n, m>(_ matrix: _Matrix<n, m, R>, _ res: MatrixEliminationResultImpl<R>) {
        self.res = res
    }
    
    public var result: _Matrix<n, m, R> {
        return _Matrix(res.result)
    }
    
    public var left: _Matrix<n, n, R> {
        return _Matrix(res.left)
    }
    
    public var leftInverse: _Matrix<n, n, R> {
        return _Matrix(res.leftInverse)
    }
    
    public var right: _Matrix<m, m, R> {
        return _Matrix(res.right)
    }
    
    public var rightInverse: _Matrix<m, m, R> {
        return _Matrix(res.rightInverse)
    }
    
    public var rank: Int {
        return res.rank
    }
    
    public var nullity: Int {
        return res.nullity
    }
    
    public var diagonal: [R] {
        return res.diagonal
    }
    
    public var kernelMatrix: _Matrix<m, Dynamic, R> {
        return _Matrix(res.kernelMatrix)
    }
    
    public var imageMatrix: _Matrix<n, Dynamic, R> {
        return _Matrix(res.imageMatrix)
    }
    
    // The left inverse of kernelMatrix
    public var kernelTransitionMatrix: _Matrix<Dynamic, m, R> {
        return _Matrix(res.kernelTransitionMatrix)
    }
}

public extension MatrixEliminationResult where n == m {
    public var inverse: _Matrix<n, n, R>? {
        return res.inverse.map{ _Matrix($0) }
    }
    
    public var determinant: R {
        return res.determinant
    }
}
