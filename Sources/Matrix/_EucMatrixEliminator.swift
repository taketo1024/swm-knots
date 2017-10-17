//
//  EucMatrixElimination.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/08/02.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

private enum Phase {
    case Init
    case Rows
    case Cols
    case Diag
}

public class _EucMatrixEliminator<R: EuclideanRing, n: _Int, m: _Int>: MatrixEliminator<R, n, m> {
    private var phase: Phase = .Init
    private var targetRow = 0
    private var targetCol = 0
    
    private var rowOperation: RowOperationMatrix<R>!
    private var colOperation: ColOperationMatrix<R>!

    override func iteration() -> Bool {
        switch phase {
        case .Init: return toNextPhase()
        case .Rows: return doRows()
        case .Cols: return doCols()
        case .Diag: return true
        }
    }
    
    func toNextPhase() -> Bool {
        switch phase {
        case .Init:
            rowOperation = RowOperationMatrix(result)
            phase = .Rows
            return false
            
        case .Rows :
            if rowOperation.isDiagonal {
                result = Matrix(rows: rows, cols: cols, type: result.type, grid: rowOperation.toGrid)
                phase = .Diag
            } else {
                colOperation = ColOperationMatrix(rowOperation)
                rowOperation = nil
                targetRow = 0
                targetCol = 0
                phase = .Cols
            }

            return false
            
        case .Cols :
            if colOperation.isDiagonal {
                result = Matrix(rows: rows, cols: cols, type: result.type, grid: colOperation.toGrid)
                phase = .Diag
            } else {
                rowOperation = RowOperationMatrix(colOperation)
                colOperation = nil
                targetRow = 0
                targetCol = 0
                phase = .Rows
            }
            return false

        default:
            return false
        }
    }
    
    func doRows() -> Bool {
        if targetRow >= rows || targetCol >= cols {
            return toNextPhase()
        }
        
        var elements = rowOperation.elements(below: targetRow, col: targetCol)
        
        // skip col if empty
        if elements.isEmpty {
            targetCol += 1
            return false
        }
        
        // initial pivot
        var (i0, a0) = findMin(elements)
        
        // eliminate until there is only one non-zero element left
        elim: while elements.count > 1 {
            for (k, e) in elements.enumerated() {
                let (i, a) = e
                if i == i0 {
                    continue
                }
                
                let (q, r) = a /% a0
                if q != 0 {
                    apply(&rowOperation!, .AddRow(at: i0, to: i, mul: -q))
                }
                
                if r == 0 {
                    elements.remove(at: k)
                    continue elim
                } else {
                    elements[k] = (i, r)
                    (i0, a0) = (i, r)
                    continue elim
                }
            }
        }
        
        // final step for this col
        let (i, a) = elements.first!
        if i != targetRow {
            apply(&rowOperation!, .SwapRows(i, targetRow))
        }
        
        for i in 0 ..< targetRow {
            let b = rowOperation[i, targetCol]
            let (q, _) = b /% a
            if q != 0 {
                apply(&rowOperation!, .AddRow(at: targetRow, to: i, mul: -q))
            }
        }
        
        targetRow += 1
        targetCol += 1
        return false
    }
    
    func doCols() -> Bool {
        if targetRow >= rows || targetCol >= cols {
            return toNextPhase()
        }
        
        var elements = colOperation.elements(row:targetRow, after: targetCol)
        
        // skip col if empty
        if elements.isEmpty {
            targetRow += 1
            return false
        }
        
        // initial pivot
        var (j0, a0) = findMin(elements)
        
        // eliminate until there is only one non-zero element left
        elim: while elements.count > 1 {
            for (k, e) in elements.enumerated() {
                let (j, a) = e
                if j == j0 {
                    continue
                }
                
                let (q, r) = a /% a0
                if q != 0 {
                    apply(&colOperation!, .AddCol(at: j0, to: j, mul: -q))
                }
                
                if r == 0 {
                    elements.remove(at: k)
                    continue elim
                } else {
                    elements[k] = (j, r)
                    (j0, a0) = (j, r)
                    continue elim
                }
            }
        }
        
        // final step for this col
        let (j, a) = elements.first!
        if j != targetCol {
            apply(&colOperation!, .SwapCols(j, targetCol))
        }
        
        for j in 0 ..< targetCol {
            let b = colOperation[targetRow, j]
            let (q, _) = b /% a
            
            if q != 0 {
                apply(&colOperation!, .AddCol(at: targetCol, to: j, mul: -q))
            }
        }
        
        targetRow += 1
        targetCol += 1
        return false
    }
    
    private func findMin(_ elements: [(Int, R)]) -> (Int, R) {
        var cand = elements.first!
        for (i, a) in elements {
            if a.isInvertible {
                return (i, a)
            }
            if a.degree < cand.1.degree {
                cand = (i, a)
            }
        }
        return cand
    }
    
    func apply(_ target: inout RowOperationMatrix<R>, _ s: EliminationStep<R>) {
        s.apply(to: &target)
        process.append(s)
        
        // TODO remove
        log("\(process.count): \(s) \n\n\( DynamicMatrix(rows: rowOperation.rows, cols: rowOperation.cols, grid: rowOperation.toGrid).detailDescription)\n")
    }
    
    func apply(_ target: inout ColOperationMatrix<R>, _ s: EliminationStep<R>) {
        s.apply(to: &target)
        process.append(s)
        
        // TODO remove
        log("\(process.count): \(s) \n\n\( DynamicMatrix(rows: colOperation.rows, cols: colOperation.cols, grid: colOperation.toGrid).detailDescription)\n")
    }
}
