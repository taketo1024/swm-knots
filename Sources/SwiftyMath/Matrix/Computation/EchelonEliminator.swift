//
//  EchelonEliminator.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/11/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

internal final class RowEchelonEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    var targetRow = 0
    var targetCol = 0
    
    override var resultType: MatrixEliminationResultImpl<R>.Type {
        return RowEchelonEliminationResult.self
    }
    
    override func prepare() {
        target.switchAlignment(.Rows)
    }
    
    override func isDone() -> Bool {
        return targetRow >= target.table.count || targetCol >= cols
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    override func iteration() {
        
        // find pivot point
        let elements = targetColElements()
        guard let (i0, a0) = pivot(elements) else {
            targetCol += 1
            return
        }
        
        // eliminate target col
        
        var again = false
        
        for (i, a) in elements {
            if i == i0 {
                continue
            }
            
            let (q, r) = a /% a0
            apply(.AddRow(at: i0, to: i, mul: -q))
            
            if r != .zero {
                again = true
            }
        }
        
        if again {
            return
        }
        
        // final step
        
        if a0.normalizeUnit != .identity {
            apply(.MulRow(at: i0, by: a0.normalizeUnit))
        }
        
        if i0 != targetRow {
            apply(.SwapRows(i0, targetRow))
        }
        
        targetRow += 1
        targetCol += 1
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    private func targetColElements() -> [(Int, R)] {
        // Take (i, a)'s from table = [ i : [ (j, a) ] ]
        // where (i >= targetRow && j == targetCol)
        return target.table.compactMap{ (i, list) -> (Int, R)? in
            let (j, a) = list.first!
            return (i >= targetRow && j == targetCol) ? (i, a) : nil
        }.sorted{ (i, _) in i}
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    private func pivot(_ candidates: [(Int, R)]) -> (Int, R)? {
        if candidates.isEmpty {
            return nil
        }
        
        var (i0, a0) = candidates.first!
        var w0 = rowWeight(i0)
        
        for (i, a) in candidates {
            let w = rowWeight(i)
            if (a.eucDegree < a0.eucDegree) || (a.eucDegree == a0.eucDegree && w < w0) {
                (i0, a0, w0) = (i, a, w)
            }
        }
        return (i0, a0)
    }
    
    private func rowWeight(_ i: Int) -> Int {
        return target.table[i]!.sum{ $0.1.eucDegree }
    }
}

internal final class RowEchelonEliminationResult<R: EuclideanRing>: MatrixEliminationResultImpl<R> {
    override func _rank() -> Int {
        return result.table.count
    }
}

internal final class ColEchelonEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    var done = false
    override func isDone() -> Bool {
        return done
    }
    
    override func iteration() {
        runTranpose(RowEchelonEliminator.self)
        done = true
    }
}
