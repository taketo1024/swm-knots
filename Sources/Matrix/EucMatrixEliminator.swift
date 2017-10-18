//
//  EucMatrixElimination.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/08/02.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class EucMatrixEliminator<R: EuclideanRing, n: _Int, m: _Int>: MatrixEliminator<R, n, m> {
    override func iteration() -> Bool {
        
        // Exit if iterations are over.
        if itr >= min(rows, cols) {
            return true
        }
        
        // Find next pivot.
        guard var (i0, j0, _) = next() else {
            return true
        }
        
        elimination: while true {
            if !eliminateRow(&i0, j0) {
                continue elimination
            }
            
            if !eliminateCol(i0, &j0) {
                continue elimination
            }
            
            if !result[i0, j0].isInvertible {
                let a = result[i0, j0]
                for i in itr ..< rows {
                    for j in itr ..< cols {
                        if i == i0 || j == j0 || result[i, j] == 0 {
                            continue
                        }
                        
                        let b = result[i, j]
                        if b % a != 0 {
                            apply(.AddRow(at: i, to: i0, mul: 1))
                            continue elimination
                        }
                    }
                }
            }
            break elimination
        }
        
        let a = result[i0, j0]
        if a.normalizeUnit != 1 {
            apply(.MulRow(at: i0, by: a.normalizeUnit))
        }
        
        if i0 > itr {
            apply(.SwapRows(itr, i0))
        }
        
        if j0 > itr {
            apply(.SwapCols(itr, j0))
        }
        
        return false
    }
    
    private func next() -> MatrixComponent<R>? {
        var (i0, j0, a0) = (0, 0, R.zero)
        
        var iterator = MatrixIterator(result,
                                      direction: .Cols,
                                      rowRange: itr ..< result.rows,
                                      colRange: itr ..< result.cols,
                                      proceedLines: true,
                                      nonZeroOnly: true)
        
        while let c = iterator.next() {
            let a = c.value
            if a.isInvertible {
                return c
            }
            
            if a0 == 0 || a.degree < a0.degree {
                (i0, j0, a0) = c
            }
        }
        
        if a0 != 0 {
            return (i0, j0, a0)
        } else {
            return nil
        }
    }
    
    private func eliminateRow(_ i0: inout Int, _ j0: Int) -> Bool {
        let a = result[i0, j0]
        
        for i in itr ..< rows {
            if i == i0 || result[i, j0] == 0 {
                continue
            }
            
            let b = result[i, j0]
            let (q, r) = b /% a
            
            apply(.AddRow(at: i0, to: i, mul: -q))
            
            if r != 0 {
                i0 = i
                return false
            }
        }
        
        return true
    }
    
    private func eliminateCol(_ i0: Int, _ j0: inout Int) -> Bool {
        let a = result[i0, j0]
        
        for j in itr ..< cols {
            if j == j0 || result[i0, j] == 0 {
                continue
            }
            
            let b = result[i0, j]
            let (q, r) = b /% a
            
            apply(.AddCol(at: j0, to: j, mul: -q))
            
            if r != 0 {
                j0 = j
                return false
            }
        }
        
        return true
    }
}
