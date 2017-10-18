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
    
    private var diag: [R] = [] // TODO rename to diagonal
    private var diagIndex = 0

    override func iteration() -> Bool {
        switch phase {
        case .Init: return toNextPhase()
        case .Rows: return doRows()
        case .Cols: return doCols()
        case .Diag: return doDiag()
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
                result = Matrix(rows: rows, cols: cols, type: result.type, grid: rowOperation.toGrid) // TODO delete
                diag = rowOperation.diagonal
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
                result = Matrix(rows: rows, cols: cols, type: result.type, grid: colOperation.toGrid) // TODO delete
                diag = colOperation.diagonal
                phase = .Diag
            } else {
                rowOperation = RowOperationMatrix(colOperation)
                colOperation = nil
                targetRow = 0
                targetCol = 0
                phase = .Rows
            }
            return false

        case .Diag:
            return doFinal()
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
    
    func doDiag() -> Bool {
        if diagIndex >= diag.count {
            return toNextPhase()
        }
        
        // SNF is complete
        if (0 ..< diag.count - 1).forAll({ i in diag[i + 1] % diag[i] == 0 }) {
            return toNextPhase()
        }
        
        let (k, a) = findMin(diag[diagIndex...].enumerated().toArray())
        let i = k + diagIndex
        
        if !a.isInvertible {
            for j in diagIndex ..< diag.count {
                if i == j {
                    continue
                }
                
                let b = diag[j]
                if b % a != 0 {
                    diagonalGCD(i, j)
                    return false
                }
            }
        }
        
        // now `a` divides all other elements.
        
        if i != diagIndex {
            diag[i] = diag[diagIndex]
            diag[diagIndex] = a
            
            process.append(.SwapRows(i, diagIndex))
            process.append(.SwapCols(i, diagIndex))
        }
        
        diagIndex += 1
        return false
    }
    
    func doFinal() -> Bool {
        var grid = Array(repeating: R.zero, count: rows * cols)
        var p = UnsafeMutablePointer(&grid)
        
        for a in diag {
            p.pointee = a
            p += (cols + 1)
        }
        
        self.result = Matrix(rows: rows, cols: cols, type: self.result.type, grid: grid)
        return true
    }
    
    private func findMin(_ elements: [(Int, R)]) -> (Int, R) {
        var cand = (-1, R.zero)
        for (i, a) in elements {
            if a.isInvertible {
                return (i, a)
            }
            if cand.0 == -1 || a.degree < cand.1.degree {
                cand = (i, a)
            }
        }
        return cand
    }
    
    private func diagonalGCD(_ i: Int, _ j: Int) {
        let (a, b) = (diag[i], diag[j])
        let (x, y, r) = bezout(a, b) // ax + by = r
        
        diag[i] = r
        diag[j] = -a * b / r // == lcm(a, b)
        
        process.append(.AddRow(at: i, to: j, mul: x))     // [a, 0; ax, b]
        process.append(.AddCol(at: j, to: i, mul: y))     // [a, 0;  r, b]
        process.append(.AddRow(at: j, to: i, mul: -a/r))  // [0, -ab/r; r, b]
        process.append(.AddCol(at: i, to: j, mul: -b/r))  // [0, -ab/r; r, 0]
        process.append(.SwapRows(i, j))                   // [r, 0; 0, -ab/r]
        
        print(process.count)
    }
    
    func apply(_ target: inout RowOperationMatrix<R>, _ s: EliminationStep<R>) {
        s.apply(to: &target)
        process.append(s)
        
        log("\(process.count): \(s) \n\n\( DynamicMatrix(rows: target.rows, cols: target.cols, grid: target.toGrid).detailDescription)\n")
    }
    
    func apply(_ target: inout ColOperationMatrix<R>, _ s: EliminationStep<R>) {
        s.apply(to: &target)
        process.append(s)
        
        log("\(process.count): \(s) \n\n\( DynamicMatrix(rows: target.rows, cols: target.cols, grid: target.toGrid).detailDescription)\n")
    }
}
