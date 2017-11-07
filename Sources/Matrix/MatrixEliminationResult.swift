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
    internal let process: [MatrixEliminator<R>.MatrixEliminationStep]
    public let form: MatrixForm
    
    internal init(_ result: ComputationalMatrix<R>, _ process: [MatrixEliminator<R>.MatrixEliminationStep], _ form: MatrixForm) {
        self.result = result
        self.process = process
        self.form = form
    }
    
    public lazy var diagonal: [R] = { [unowned self] in
        assert(form == .Diagonal || form == .Smith)
        return result.diagonal
    }()
    
    public var rank: Int {
        return diagonal.count
    }
    
    public lazy var left: ComputationalMatrix<R> = { [unowned self] in
        let P = ComputationalMatrix<R>.identity(result.rows)
        
        process.lazy
               .filter { $0.isRowOperation }
               .forEach { $0.apply(to: P) }
        
        return P
    }()
    
    public lazy var leftInverse: ComputationalMatrix<R> = { [unowned self] in
        let P = ComputationalMatrix<R>.identity(result.rows)
        
        process.lazy
               .filter { $0.isRowOperation }
               .reversed()
               .forEach { $0.inverse.apply(to: P) }
        
        return P
    }()
    
    public lazy var right: ComputationalMatrix<R> = { [unowned self] in
        let P = ComputationalMatrix<R>.identity(result.cols, align: .Cols)
        
        process.lazy
               .filter{ $0.isColOperation }
               .forEach { $0.apply(to: P) }
        
        return P
    }()
    
    public lazy var rightInverse: ComputationalMatrix<R> = { [unowned self] in
        let P = ComputationalMatrix<R>.identity(result.cols, align: .Cols)
        
        process.lazy
               .filter { $0.isColOperation }
               .reversed()
               .forEach { $0.inverse.apply(to: P) }
        
        return P
    }()
}
