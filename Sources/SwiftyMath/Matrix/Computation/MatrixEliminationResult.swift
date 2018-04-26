//
//  MatrixEliminator.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/06/09.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class MatrixEliminationResult<R: EuclideanRing> {
    public let result: MatrixImpl<R>
    internal let rowOps: [MatrixEliminator<R>.ElementaryOperation]
    internal let colOps: [MatrixEliminator<R>.ElementaryOperation]
    public let form: MatrixForm
    
    public required init(_ result: MatrixImpl<R>, _ rowOps: [MatrixEliminator<R>.ElementaryOperation], _ colOps: [MatrixEliminator<R>.ElementaryOperation], _ form: MatrixForm) {
        self.result = result
        self.rowOps = rowOps
        self.colOps = colOps
        self.form = form
    }
    
    public final lazy var left: MatrixImpl<R>         = _left()
    public final lazy var leftInverse: MatrixImpl<R>  = _leftInverse()
    public final lazy var right: MatrixImpl<R>        = _right()
    public final lazy var rightInverse: MatrixImpl<R> = _rightInverse()
    public final lazy var rank: Int                            = _rank()
    public final lazy var diagonal: [R]                        = _diagonal()
    public final lazy var inverse: MatrixImpl<R>?     = _inverse()
    public final lazy var determinant: R                       = _determinant()
    public final lazy var kernelMatrix: MatrixImpl<R> = _kernelMatrix()
    public final lazy var imageMatrix: MatrixImpl<R>  = _imageMatrix()
    public final lazy var kernelTransitionMatrix: MatrixImpl<R> = _kernelTransitionMatrix()

    public final var nullity: Int {
        return result.cols - rank
    }
    
    public final var isInjective: Bool {
        return result.cols <= result.rows && rank == result.cols
    }
    
    public final var isSurjective: Bool {
        return result.cols >= result.rows && rank == result.rows && diagonal.forAll{ $0.isInvertible }
    }
    
    public final var isBijective: Bool {
        return isInjective && isSurjective
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    internal final func _left() -> MatrixImpl<R> {
        let P = MatrixImpl<R>.identity(result.rows)
        for s in rowOps {
            s.apply(to: P)
        }
        return P
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    internal final func _leftInverse(restrictedToCols colRange: CountableRange<Int>? = nil) -> MatrixImpl<R> {
        let P = (colRange == nil)
            ? MatrixImpl<R>.identity(result.rows)
            : MatrixImpl<R>.identity(result.rows).submatrix(colRange: colRange!)
        
        for s in rowOps.reversed() {
            s.inverse.apply(to: P)
        }
        
        return P
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    internal final func _right() -> MatrixImpl<R> {
        let P = MatrixImpl<R>.identity(result.cols, align: .Cols)
        for s in colOps {
            s.apply(to: P)
        }
        return P
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    internal final func _rightInverse(restrictedToRows rowRange: CountableRange<Int>? = nil) -> MatrixImpl<R> {
        let P = (rowRange == nil)
            ? MatrixImpl<R>.identity(result.cols, align: .Cols)
            : MatrixImpl<R>.identity(result.cols, align: .Cols).submatrix(rowRange: rowRange!)
        
        for s in colOps.reversed() {
            s.inverse.apply(to: P)
        }
        
        return P
    }
    
    // override points
    
    internal func _rank() -> Int {
        fatalError("not available.")
    }
    
    internal func _diagonal() -> [R]{
        fatalError("not available.")
    }
    
    internal func _inverse() -> MatrixImpl<R>? {
        fatalError("not available.")
    }
    
    internal func _determinant() -> R {
        fatalError("not available.")
    }
    
    internal func _kernelMatrix() -> MatrixImpl<R> {
        fatalError("not available.")
    }
    
    internal func _imageMatrix() -> MatrixImpl<R> {
        fatalError("not available.")
    }
    
    internal func _kernelTransitionMatrix() -> MatrixImpl<R> {
        fatalError("not available.")
    }
}

// A Wrapper struct for Matrix<n, m, R> types.

public struct MatrixEliminationResultWrapper<n: _Int, m: _Int, R: EuclideanRing> {
    private let res: MatrixEliminationResult<R>
    
    public init<n, m>(_ matrix: _Matrix<n, m, R>, _ res: MatrixEliminationResult<R>) {
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
}

public extension MatrixEliminationResultWrapper where n == m {
    public var inverse: _Matrix<n, n, R>? {
        return res.inverse.map{ _Matrix($0) }
    }
    
    public var determinant: R {
        return res.determinant
    }
}
