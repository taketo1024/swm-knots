//
//  HermiteEliminator.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/11/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public final class RowHermiteEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    internal var targetRow = 0
    internal var targetCol = 0
    internal var rank = 0

    override func prepare() {
        run(RowEchelonEliminator.self)
        rank = target.table.count
    }
    
    override func isDone() -> Bool {
        return targetRow >= rank || targetCol >= cols
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    internal override func iteration() {
        let a0 = target[targetRow, targetCol]
        if a0 == .zero {
            targetCol += 1
            return
        }
        
        for i in 0 ..< targetRow {
            let a = target[i, targetCol]
            if a == .zero {
                continue
            }
            
            let q = a / a0
            if q != .zero {
                apply(.AddRow(at: targetRow, to: i, mul: -q))
            }
        }
        
        targetRow += 1
        targetCol += 1
    }
}

public final class ColHermiteEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    internal var done = false
    override func isDone() -> Bool {
        return done
    }
    
    internal override func iteration() {
        runTranpose(RowHermiteEliminator.self)
        done = true
    }
}
