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
}
