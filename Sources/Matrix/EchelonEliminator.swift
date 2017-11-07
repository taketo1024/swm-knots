//
//  EchelonEliminator.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public final class RowEchelonEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    internal var targetRow = 0
    internal var targetCol = 0
    
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, process, .RowEchelon)
    }
    
    override func prepare() {
        target.switchAlignment(.Rows)
    }
    
    @_specialize(where R == IntegerNumber)
    override func iteration() -> Bool {
        if targetRow >= rows || targetCol >= cols {
            return true
        }
        
        // find pivot point
        let targetElements = target.enumerate(col: targetCol, fromRow: targetRow, headsOnly: true)
        guard let (i0, a0) = findMin(targetElements) else {
            targetCol += 1
            return false
        }
        
        // eliminate target col
        for (i, a) in targetElements {
            if i == i0 {
                continue
            }
            
            let (q, r) = a /% a0
            apply(.AddRow(at: i0, to: i, mul: -q))
            
            if r != 0 {
                return false
            }
        }
        
        // final step
        if a0.normalizeUnit != R.identity {
            apply(.MulRow(at: i0, by: a0.normalizeUnit))
        }
        
        if i0 != targetRow {
            apply(.SwapRows(i0, targetRow))
        }
        
        targetRow += 1
        targetCol += 1
        
        return false
    }
}

public final class ColEchelonEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    public override var result: MatrixEliminationResult<R> {
        return MatrixEliminationResult(target, process, .ColEchelon)
    }
    
    internal override func iteration() -> Bool {
        runTranpose(RowEchelonEliminator.self)
        return true
    }
}
