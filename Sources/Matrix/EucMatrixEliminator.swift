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
        let doRows = (mode != .Cols)
        let doCols = (mode != .Rows)
        
        guard var (i0, j0, _) = next() else {
            if mode == .Both { // The area left is O. Exit iteration.
                return false
            } else {           // The target row/col is O. Continue iteration.
                return true
            }
        }
        
        elimination: while true {
            if doRows && !eliminateRow(&i0, j0) {
                continue elimination
            }
            if doCols && !eliminateCol(i0, &j0) {
                continue elimination
            }
            
            if doRows && doCols && !result[i0, j0].isInvertible {
                let a = result[i0, j0]
                for i in itr ..< rows {
                    for j in itr ..< cols {
                        if i == i0 || j == j0 || result[i, j] == 0 {
                            continue
                        }
                        
                        let b = result[i, j]
                        if b % a != 0 {
                            self.apply(.AddRow(at: i, to: i0, mul: 1))
                            continue elimination
                        }
                    }
                }
            }
            break elimination
        }
        
        // TODO maybe implement NumberType or Comparable
        if R.self == IntegerNumber.self && (result[i0, j0] as! IntegerNumber) < 0 {
            if doRows {
                self.apply(.MulRow(at: i0, by: -1))
            } else {
                self.apply(.MulCol(at: j0, by: -1))
            }
        }
        
        if doRows && i0 > itr {
            self.apply(.SwapRows(itr, i0))
        }
        
        if doCols && j0 > itr {
            self.apply(.SwapCols(itr, j0))
        }
        
        return true
    }
    
    private func next() -> MatrixComponent<R>? {
        var (i0, j0, a0) = (0, 0, R.zero)
        
        var iterator = MatrixIterator(result,
                                      direction: (mode != .Cols) ? .Cols : .Rows,
                                      rowRange: itr ..< result.rows,
                                      colRange: itr ..< result.cols,
                                      proceedLines: (mode == .Both),
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
            
            self.apply(.AddRow(at: i0, to: i, mul: -q))
            
            if r != 0 {
                i0 = i
                return false
            }
        }
        
        // at this point, it is guaranteed that result[i, j0] == 0 for (i >= itr, i != i0)
        
        if mode == .Rows {
            for i in 0 ..< itr {
                if i == i0 || result[i, j0] == 0 {
                    continue
                }
                
                let b = result[i, j0]
                let (q, _) = b /% a
                
                self.apply(.AddRow(at: i0, to: i, mul: -q))
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
            
            self.apply(.AddCol(at: j0, to: j, mul: -q))
            
            if r != 0 {
                j0 = j
                return false
            }
        }
        
        // at this point, it is guaranteed that result[i0, j] == 0 for (j >= itr, j != j0)
        
        if mode == .Cols {
            for j in 0 ..< itr {
                if j == j0 || result[i0, j] == 0 {
                    continue
                }
                
                let b = result[i0, j]
                let (q, _) = b /% a
                
                self.apply(.AddCol(at: j0, to: j, mul: -q))
            }
        }
        
        return true
    }
}
