//
//  FieldMatrixElimination.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/08/02.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class FieldMatrixEliminator<n: _Int, m: _Int, R: Field>: MatrixEliminator<n, m, R> {
    override func iteration() -> Bool {
        
        // Exit if iterations are over.
        if itr >= min(rows, cols) {
            return true
        }
        
        // Find next pivot.
        guard var (i0, j0, _) = next() else {
            return true
        }
        
        if i0 > itr {
            apply(.SwapRows(itr, i0))
            i0 = itr
        }
        
        if j0 > itr {
            apply(.SwapCols(itr, j0))
            j0 = itr
        }
        
        eliminateRow(i0, j0)
        eliminateCol(i0, j0)
        
        return false
    }
    
    private func next() -> MatrixComponent<R>? {
        var iterator = MatrixIterator(result,
                              direction: .Cols,
                              rowRange: itr ..< result.rows,
                              colRange: itr ..< result.cols,
                              proceedLines: true,
                              nonZeroOnly: true)
        
        return iterator.next()
    }
    
    private func eliminateRow(_ i0: Int, _ j0: Int) {
        let a = result[i0, j0]
        if a != R.identity {
            apply(.MulRow(at: i0, by: a.inverse!))
        }
        
        for i in 0 ..< rows {
            if i == i0 || result[i, j0] == 0 {
                continue
            }
            
            apply(.AddRow(at: i0, to: i, mul: -result[i, j0]))
        }
    }
    
    private func eliminateCol(_ i0: Int, _ j0: Int) {
        let a = result[i0, j0]
        if a != R.identity {
            apply(.MulCol(at: i0, by: a.inverse!))
        }
        
        for j in 0 ..< cols {
            if j == j0 || result[i0, j] == 0 {
                continue
            }
            
            apply(.AddCol(at: j0, to: j, mul: -result[i0, j]))
        }
    }
}
