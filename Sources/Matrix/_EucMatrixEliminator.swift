//
//  EucMatrixElimination.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/08/02.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// "A new algorithm for computing the Smith normal form and its implementation on parallel machines"
// Gerold J ̈ager
// https://www.informatik.uni-kiel.de/~gej/publ/parsmith2.pdf

private enum Phase {
    case INIT
    case HNF
    case BAND
    case DIAG
}

public class _EucMatrixEliminator<R: EuclideanRing, n: _Int, m: _Int>: MatrixEliminator<R, n, m> {
    private var phase = Phase.INIT
    
    override func iteration() -> Bool {
        switch phase {
        case .INIT: return toNextPhase()
        case .HNF : return doHNF()
        case .BAND: return toNextPhase() // TODO
        case .DIAG: return toNextPhase() // TODO
        }
    }
    
    func toNextPhase() -> Bool {
        switch phase {
        case .INIT:
            HNFTarget = RowOperationMatrix(result)
            phase = .HNF
            log("\(itr): HNF start \n")
            return false
            
        case .HNF :
            phase = .BAND
            log("\(itr): BAND start \n")
            return false
            
        case .BAND:
            phase = .DIAG
            log("\(itr): DIAG start \n")
            return false
            
        case .DIAG:
            return true
        }
    }
    
    private var HNFTarget: RowOperationMatrix<R, n, m>!
    private var HNFTargetRow = 0
    private var HNFTargetCol = 0

    func doHNF() -> Bool {
        if HNFTargetRow >= rows || HNFTargetCol >= cols {
            return toNextPhase()
        }
        
        var elements = HNFTarget.elements(below: HNFTargetRow, col: HNFTargetCol)
        
        // skip col if empty
        if elements.isEmpty {
            HNFTargetCol += 1
            return false
        }
        
        // initial pivot
        var (i0, a0): (Int, R) = {
            var cand = elements.first!
            for (i, a) in elements {
                if a.isInvertible {
                    return (i, a)
                }
                if a.degree < cand.value.degree {
                    cand = (i, a)
                }
            }
            return cand
        }()
        
        // eliminate until there is only one non-zero element left
        elim: while elements.count > 1 {
            for (k, e) in elements.enumerated() {
                let (i, a) = e
                if i == i0 {
                    continue
                }
                
                let (q, r) = a /% a0
                apply(&HNFTarget!, .AddRow(at: i0, to: i, mul: -q))
                
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
        if i != HNFTargetRow {
            apply(&HNFTarget!, EliminationStep.SwapRows(i, HNFTargetRow))
        }
        
        for i in 0 ..< HNFTargetRow {
            let b = HNFTarget[i, HNFTargetCol]
            let (q, _) = b /% a
            apply(&HNFTarget!, .AddRow(at: HNFTargetRow, to: i, mul: -q))
        }
        
        HNFTargetRow += 1
        HNFTargetCol += 1
        return false
    }
    
    func apply(_ target: inout RowOperationMatrix<R, n, m>, _ s: EliminationStep<R>) {
        s.apply(to: &target)
        process.append(s)
        
        // TODO remove
        log("\(itr): \(s) \n\n\(HNFTarget.toMatrix.detailDescription)\n")
    }
}
