//
//  MatrixEliminator.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/09.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class MatrixEliminationResult<R: EuclideanRing> {
    public let result: ComputationalMatrix<R>
    internal let rowOps: [MatrixEliminator<R>.ElementaryOperation]
    internal let colOps: [MatrixEliminator<R>.ElementaryOperation]
    public let form: MatrixForm
    
    public required init(_ result: ComputationalMatrix<R>, _ rowOps: [MatrixEliminator<R>.ElementaryOperation], _ colOps: [MatrixEliminator<R>.ElementaryOperation], _ form: MatrixForm) {
        self.result = result
        self.rowOps = rowOps
        self.colOps = colOps
        self.form = form
    }
    
    public lazy var diagonal: [R] = { [unowned self] in
        assert(form == .Diagonal || form == .Smith)
        return result.diagonal
    }()
    
    public var rank: Int {
        return diagonal.count
    }
    
    public lazy var inverse: ComputationalMatrix<R>? = {
        assert(result.rows == result.cols)
        assert(form == .Diagonal || form == .Smith)
        return (rank == result.rows) ? right * left : nil
    }()
    
    public lazy var determinant: R = { [unowned self] in
        assert(result.rows == result.cols)
        assert(form == .Diagonal || form == .Smith)
        
        if rank == result.rows {
            return rowOps.multiply { $0.determinant }.inverse!
                 * colOps.multiply { $0.determinant }.inverse!
                 * diagonal.multiplyAll()
        } else {
            return 0
        }
    }()
    
    public lazy var left: ComputationalMatrix<R> = { [unowned self] in
        return self._left()
    }()
    
    @_specialize(where R == IntegerNumber)
    private func _left() -> ComputationalMatrix<R> {
        let P = ComputationalMatrix<R>.identity(result.rows)
        for s in rowOps {
            s.apply(to: P)
        }
        return P
    }
    
    public lazy var leftInverse: ComputationalMatrix<R> = { [unowned self] in
        return self._leftInverse()
    }()
    
    @_specialize(where R == IntegerNumber)
    private func _leftInverse(restrictedToCols colRange: CountableRange<Int>? = nil) -> ComputationalMatrix<R> {
        let P = (colRange == nil)
            ? ComputationalMatrix<R>.identity(result.rows)
            : ComputationalMatrix<R>.identity(result.rows).submatrix(colRange: colRange!)
        
        for s in rowOps.reversed() {
            s.inverse.apply(to: P)
        }
        
        return P
    }
    
    public lazy var right: ComputationalMatrix<R> = { [unowned self] in
        return self._right()
    }()
    
    @_specialize(where R == IntegerNumber)
    private func _right() -> ComputationalMatrix<R> {
        let P = ComputationalMatrix<R>.identity(result.cols, align: .Cols)
        for s in colOps {
            s.apply(to: P)
        }
        return P
    }
    
    public lazy var rightInverse: ComputationalMatrix<R> = { [unowned self] in
        return self._rightInverse()
    }()
    
    @_specialize(where R == IntegerNumber)
    private func _rightInverse(restrictedToRows rowRange: CountableRange<Int>? = nil) -> ComputationalMatrix<R> {
        let P = (rowRange == nil)
            ? ComputationalMatrix<R>.identity(result.cols, align: .Cols)
            : ComputationalMatrix<R>.identity(result.cols, align: .Cols).submatrix(rowRange: rowRange!)
        
        for s in colOps.reversed() {
            s.inverse.apply(to: P)
        }
        
        return P
    }
    
    // The matrix made by the basis of Ker(A).
    // Z = (z1, ..., zk) , k = col(A) - rank(A).
    //
    // P * A * Q = [D_r; O_k]
    // =>  Z = Q[:, r ..< m] = Q * [O_r; I_k]

    public lazy var kernelMatrix: ComputationalMatrix<R> = { [unowned self] in
        return right.submatrix(colRange: rank ..< result.cols)
    }()
    
    // The matrix made by the basis of Im(A).
    // B = (b1, ..., br) , r = rank(A)
    //
    // P * A * Q = [D_r; O_k]
    // => D is the imageMatrix with basis P.
    // => P^-1 * D is the imageMatrix with the standard basis.

    public lazy var imageMatrix: ComputationalMatrix<R> = { [unowned self] in
        let A = _leftInverse(restrictedToCols: 0 ..< rank)
        
        for (j, a) in diagonal.enumerated() {
            if j >= rank { break }
            A.multiplyCol(at: j, by: a)
        }
        
        return A
    }()
    
    // T: The basis transition matrix from (ei) to (zi),
    // i.e. T * zi = ei.
    //
    // P * A * Q = [D_r; O_k]
    // =>  Z = Q[:, r ..< m] = Q * [O_r; I_k]
    // =>  Q^-1 * Z = [O; I_k]
    //
    // T = Q^-1[:, r ..< m]  gives  T * Z = I_k.
    
    public lazy var kernelTransitionMatrix: ComputationalMatrix<R> = { [unowned self] in
        return _rightInverse(restrictedToRows: rank ..< result.cols)
    }()
}

// A Wrapper struct for Matrix<n, m, R> types.

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
