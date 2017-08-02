//
//  MatrixEliminationResult.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/08/02.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct MatrixEliminationResult<R: Ring, n: _Int, m: _Int> {
    private let processor: MatrixEliminationProcessor<R>
    
    public init(_ processor: MatrixEliminationProcessor<R>) {
        self.processor = processor
    }
    
    public var result: Matrix<R, n, m> {
        return Matrix(processor.result)
    }
    
    public var left: Matrix<R, n, n> {
        return Matrix(processor.left)
    }
    
    public var leftInverse: Matrix<R, n, n> {
        return Matrix(processor.leftInverse)
    }
    
    public var right: Matrix<R, m, m> {
        return Matrix(processor.right)
    }
    
    public var rightInverse: Matrix<R, m, m> {
        return Matrix(processor.rightInverse)
    }
    
    public var diagonal: [R] {
        return processor.diagonal
    }
    
    // TODO remove below
    
    public var rank: Int {
        let A = processor.result
        let r = min(A.rows, A.cols)
        return (0 ..< r).filter{ A[$0, $0] != R.zero }.count
    }
    
    public var nullity: Int {
        return processor.result.cols - rank
    }
    
    public var kernelPart: Matrix<R, m, Dynamic> {
        return right.submatrix(colsInRange: rank ..< processor.result.cols)
    }
    
    public var kernelVectors: [ColVector<R, m>] {
        return kernelPart.toColVectors()
    }
    
    public var imagePart: Matrix<R, n, Dynamic> {
        let d = diagonal
        var a: Matrix<R, n, Dynamic> = leftInverse.submatrix(colsInRange: 0 ..< self.rank)
        (0 ..< min(d.count, a.cols)).forEach {
            a.multiplyCol(at: $0, by: d[$0])
        }
        return a
    }
    
    public var imageVectors: [ColVector<R, n>] {
        return imagePart.toColVectors()
    }

}
