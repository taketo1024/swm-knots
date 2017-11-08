//
//  HermiteEliminator.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public final class RowHermiteEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    internal var targetRow = 0
    internal var targetCol = 0
    
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, rowOps, colOps, .RowHermite)
    }
    
    override func prepare() {
        run(RowEchelonEliminator.self)
    }
    
    @_specialize(where R == IntegerNumber)
    internal override func iteration() -> Bool {
        if targetRow >= rows || targetCol >= cols {
            return true
        }
        
        let col = Array(target.enumerate(col: targetCol))
        guard let (i0, a0) = col.last, i0 >= targetRow else {
            targetCol += 1
            return false
        }
        
        for (i, a) in col {
            if i == i0 {
                break
            }
            
            let q = a / a0
            apply(.AddRow(at: i0, to: i, mul: -q))
        }
        
        targetRow += 1
        targetCol += 1
        return false
    }
}

public final class ColHermiteEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, rowOps, colOps, .ColHermite)
    }
    
    internal override func iteration() -> Bool {
        runTranpose(RowHermiteEliminator.self)
        return true
    }
}
