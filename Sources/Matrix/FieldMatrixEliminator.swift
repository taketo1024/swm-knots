//
//  FieldMatrixElimination.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/08/02.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class FieldMatrixEliminator<K: Field, n: _Int, m: _Int>: MatrixEliminator<K, n, m> {
    override func iteration() -> Bool {
        
        // Exit if iterations are over.
        switch mode {
        case .Both where itr >= min(rows, cols),
             .Rows where itr >= rows,
             .Cols where itr >= cols:
            return false
            
        default: break
        }
        
        // Find next pivot.
        guard var (i0, j0, _) = next() else {
            if mode == .Both { // The area left is O. Exit iteration.
                return false
            } else {           // The target row/col is O. Continue iteration.
                return true
            }
        }
        
        let doRows = (mode != .Cols)
        let doCols = (mode != .Rows)
        
        if doRows && i0 > itr {
            self.apply(.SwapRows(itr, i0))
            i0 = itr
        }
        
        if doCols && j0 > itr {
            self.apply(.SwapCols(itr, j0))
            j0 = itr
        }
        
        if doRows {
            eliminateRow(i0, j0)
        }
        
        if doCols {
            eliminateCol(i0, j0)
        }
        
        return true
    }
    
    private func next() -> MatrixComponent<K>? {
        var iterator = MatrixIterator(result,
                              direction: (mode != .Cols) ? .Cols : .Rows,
                              rowRange: itr ..< result.rows,
                              colRange: itr ..< result.cols,
                              proceedLines: (mode == .Both),
                              nonZeroOnly: true)
        return iterator.next()
    }
    
    private func eliminateRow(_ i0: Int, _ j0: Int) {
        let a = result[i0, j0]
        if a != K.identity {
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
        if a != K.identity {
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
