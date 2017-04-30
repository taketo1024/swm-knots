import Foundation

public func eliminateMatrix<R: EuclideanRing, n: _Int, m: _Int>(_ A: Matrix<R, n, m>) -> (B: Matrix<R, n, m>, P: Matrix<R, m, m>, Q: Matrix<R, n, n>) {
    
    var B = A
    var P = A.rightIdentity
    var Q = A.leftIdentity
    
    eliminateMatrix(&B, &P, &Q, 0)
    
    return (B, P, Q)
}

private func findNonZeroMin<R: EuclideanRing, n: _Int, m: _Int>(_ a: Matrix<R, n, m>, _ itr: Int) -> (value: R, row: Int, col: Int)? {
    return a.reduce(nil) { (result, current) -> (R, Int, Int)? in
        let (a, i, j) = current
        if i < itr || j < itr {
            return result
        }
        
        if a != 0 && (result == nil || a.degree < result!.0.degree) {
            return current
        } else {
            return result
        }
    }
}

private func eliminateMatrix<R: EuclideanRing, n: _Int, m: _Int>(_ B: inout Matrix<R, n, m>, _ P: inout Matrix<R, m, m>, _ Q: inout Matrix<R, n, n>, _ itr: Int) {
    guard var (a, i0, j0) = findNonZeroMin(B, itr) else { // when A = O
        return
    }
    
    process: while(true) {
        if !eliminateRow(&B, &Q, &i0, j0, itr) {
            continue process
        }
        if !eliminateCol(&B, &P, i0, &j0, itr) {
            continue process
        }
        
        a = B[i0, j0]
        
        for (b, i, j) in B {
            if i < itr || j < itr {
                continue
            }
            if (i, j) == (i0, j0) || b == 0 {
                continue
            }
            if b % a != 0 {
                B.addCol(at: j, to: j0)
                P.addCol(at: j, to: j0)
                continue process
            }
        }
        break process
    }
    
    // TODO maybe implement NumberType or Comparable
    if R.self == IntegerNumber.self && (B[i0, j0] as! IntegerNumber) < 0 {
        B.multiplyRow(at: i0, by: -1)
        Q.multiplyCol(at: i0, by: -1)
    }
    
    if i0 > itr {
        B.swapRows(itr, i0)
        Q.swapCols(itr, i0)
    }
    
    if j0 > itr {
        B.swapCols(itr, j0)
        P.swapCols(itr, j0)
    }
    
    if itr < min(B.rows, B.cols) - 1 {
        eliminateMatrix(&B, &P, &Q, itr + 1)
    }
}

private func eliminateRow<R: EuclideanRing, n: _Int, m: _Int>(_ B: inout Matrix<R, n, m>, _ Q: inout Matrix<R, n, n>, _ i0: inout Int, _ j0: Int, _ itr: Int) -> Bool {
    let a = B[i0, j0]
    
    for i in itr ..< B.rows {
        if i == i0 {
            continue
        }
        
        let b = B[i, j0]
        if b == 0 {
            continue
        }
        
        let (q, r) = b /% a
        
        B.addRow(at: i0, to:  i, multipliedBy: -q)
        Q.addCol(at:  i, to: i0, multipliedBy:  q)
        
        if r != 0 {
            i0 = i
            return false
        }
    }
    
    return true
}

private func eliminateCol<R: EuclideanRing, n: _Int, m: _Int>(_ B: inout Matrix<R, n, m>, _ P: inout Matrix<R, m, m>, _ i0: Int, _ j0: inout Int, _ itr: Int) -> Bool {
    let a = B[i0, j0]
    
    for j in itr ..< B.cols {
        if j == j0 {
            continue
        }
        
        let b = B[i0, j]
        if b == 0 {
            continue
        }
        
        let (q, r) = b /% a
        
        B.addCol(at: j0, to: j, multipliedBy: -q)
        P.addCol(at: j0, to: j, multipliedBy: -q)
        
        if r != 0 {
            j0 = j
            return false
        }
    }
    
    return true
}
