//
//  DiagonalEliminator.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public final class DiagonalEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, rowOps, colOps, .Diagonal)
    }
    
    override func iteration() -> Bool {
        if target.isDiagonal {
            return true
        }
        
        run(RowHermiteEliminator.self)
        
        if target.isDiagonal {
            return true
        }
        
        run(ColHermiteEliminator.self)
        
        return false
    }
}
