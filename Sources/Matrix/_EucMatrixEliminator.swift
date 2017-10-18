//
//  EucMatrixElimination.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/08/02.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

private enum Phase {
    case Rows
    case Cols
    case Diag
}

public class _EucMatrixEliminator<R: EuclideanRing, n: _Int, m: _Int>: MatrixEliminator<R, n, m> {
    private var phase: Phase
    private var targetRow = 0
    private var targetCol = 0
    
    private var rowOperation: RowOperationMatrix<R>!
    private var colOperation: ColOperationMatrix<R>!
    private var _diagonal: [R] = []
    
    public required init(_ target: Matrix<R, n, m>, _ mode: MatrixEliminationMode, _ debug: Bool) {
        self.rowOperation = RowOperationMatrix(target)
        self.phase = .Rows
        super.init(target, mode, debug)
    }
    
    public override lazy var result: Matrix<R, n, m> = { [unowned self] in
        return self.diagToMatrix()
    }()
    
    public override var diagonal: [R] {
        return _diagonal
    }

    override func iteration() -> Bool {
        switch phase {
        case .Rows: return doRows()
        case .Cols: return doCols()
        case .Diag: return doDiag()
        }
    }
    
    func toNextPhase() -> Bool {
        switch phase {
        case .Rows :
            if rowOperation.isDiagonal {
                targetRow = 0
                _diagonal = rowOperation.diagonal
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
                targetRow = 0
                _diagonal = colOperation.diagonal
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
            return true
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
                    apply(.AddRow(at: i0, to: i, mul: -q))
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
            apply(.SwapRows(i, targetRow))
        }
        
        if a.normalizeUnit != 1 {
            apply(.MulRow(at: i, by: a.normalizeUnit))
        }
        
        for i in 0 ..< targetRow {
            let b = rowOperation[i, targetCol]
            let (q, _) = b /% a
            if q != 0 {
                apply(.AddRow(at: targetRow, to: i, mul: -q))
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
                    apply(.AddCol(at: j0, to: j, mul: -q))
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
            apply(.SwapCols(j, targetCol))
        }
        
        if a.normalizeUnit != 1 {
            apply(.MulCol(at: j, by: a.normalizeUnit))
        }
        
        for j in 0 ..< targetCol {
            let b = colOperation[targetRow, j]
            let (q, _) = b /% a
            
            if q != 0 {
                apply(.AddCol(at: targetCol, to: j, mul: -q))
            }
        }
        
        targetRow += 1
        targetCol += 1
        return false
    }
    
    func doDiag() -> Bool {
        if targetRow >= _diagonal.count {
            return toNextPhase()
        }
        
        // SNF is complete
        if (0 ..< _diagonal.count - 1).forAll({ i in _diagonal[i + 1] % _diagonal[i] == 0 }) {
            return toNextPhase()
        }
        
        let (k, a) = findMin(_diagonal[targetRow...].enumerated().toArray())
        let i = k + targetRow
        
        if !a.isInvertible {
            for j in targetRow ..< _diagonal.count {
                if i == j {
                    continue
                }
                
                let b = _diagonal[j]
                if b % a != 0 {
                    diagonalGCD(i, j)
                    return false
                }
            }
        }
        
        // now `a` divides all other elements.
        
        if i != targetRow {
            swapDiagonal(i, targetRow)
        }
        
        targetRow += 1
        return false
    }
    
    private func apply(_ s: EliminationStep<R>) {
        switch phase {
        case .Rows:
            s.apply(to: &rowOperation!)
        case .Cols:
            s.apply(to: &colOperation!)
        case .Diag:
            break
        }
        addProcess(s)
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
        let (a, b) = (_diagonal[i], _diagonal[j])
        let (x, y, r) = bezout(a, b) // r = ax + by = gcd(a, b)
        let m = -a * b / r           // lcm(a, b)
        
        addProcess(.AddRow(at: i, to: j, mul: x))     // [a, 0; ax, b]
        addProcess(.AddCol(at: j, to: i, mul: y))     // [a, 0;  r, b]
        addProcess(.AddRow(at: j, to: i, mul: -a/r))  // [0, m; r, b]
        addProcess(.AddCol(at: i, to: j, mul: -b/r))  // [0, m; r, 0]
        addProcess(.SwapRows(i, j))                   // [r, 0; 0, m]
        
        if r.normalizeUnit != 1 {
            _diagonal[i] = r * r.normalizeUnit
            addProcess(.MulRow(at: i, by: r.normalizeUnit))
        } else {
            _diagonal[i] = r
        }
        
        if m.normalizeUnit != 1 {
            _diagonal[j] = m * m.normalizeUnit
            addProcess(.MulRow(at: j, by: m.normalizeUnit))
        } else {
            _diagonal[j] = m
        }
    }
    
    private func swapDiagonal(_ i: Int, _ j: Int) {
        let a = _diagonal[i]
        _diagonal[i] = _diagonal[j]
        _diagonal[j] = a
        
        addProcess(.SwapRows(i, targetRow))
        addProcess(.SwapCols(i, targetRow))
    }
    
    private func diagToMatrix() -> Matrix<R, n, m> {
        var grid = Array(repeating: R.zero, count: rows * cols)
        var p = UnsafeMutablePointer(&grid)
        
        for a in _diagonal {
            p.pointee = a
            p += (cols + 1)
        }
        return Matrix(rows: self.rows, cols: self.cols, type: self.type, grid: grid)
    }
    
    override var current: Matrix<R, n, m> {
        switch phase {
        case .Rows:
            return Matrix(rows: rows, cols: cols, grid: rowOperation.toGrid)
        case .Cols:
            return Matrix(rows: rows, cols: cols, grid: colOperation.toGrid)
        case .Diag:
            return diagToMatrix()
        }
    }
}
