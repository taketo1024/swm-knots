//
//  MatrixEliminationStep.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/10/18.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

internal enum EliminationStep<R: Ring> {
    case AddRow(at: Int, to: Int, mul: R)
    case MulRow(at: Int, by: R)
    case SwapRows(Int, Int)
    case AddCol(at: Int, to: Int, mul: R)
    case MulCol(at: Int, by: R)
    case SwapCols(Int, Int)
    
    var isRowOperation: Bool {
        switch self {
        case .AddRow, .MulRow, .SwapRows: return true
        default: return false
        }
    }
    
    var isColOperation: Bool {
        switch self {
        case .AddCol, .MulCol, .SwapCols: return true
        default: return false
        }
    }
    
    var determinant: R {
        switch self {
        case .AddRow(_, _, _), .AddCol(_, _, _):
            return R.identity
        case let .MulRow(at: _, by: r):
            return r
        case let .MulCol(at: _, by: r):
            return r
        case .SwapRows(_, _), .SwapCols(_, _):
            return -R.identity
        }
    }
    
    var inverse: EliminationStep<R> {
        switch self {
        case let .AddRow(i, j, r):
            return .AddRow(at: i, to: j, mul: -r)
        case let .AddCol(i, j, r):
            return .AddCol(at: i, to: j, mul: -r)
        case let .MulRow(at: i, by: r):
            return .MulRow(at: i, by: r.inverse!)
        case let .MulCol(at: i, by: r):
            return .MulCol(at: i, by: r.inverse!)
        case .SwapRows(_, _), .SwapCols(_, _):
            return self
        }
    }
    
    func apply<n, m>(to A: inout Matrix<R, n, m>) {
        switch self {
        case let .AddRow(i, j, r):
            A.addRow(at: i, to: j, multipliedBy: r)
        case let .MulRow(i, r):
            A.multiplyRow(at: i, by: r)
        case let .SwapRows(i, j):
            A.swapRows(i, j)
        case let .AddCol(i, j, r):
            A.addCol(at: i, to: j, multipliedBy: r)
        case let .MulCol(i, r):
            A.multiplyCol(at: i, by: r)
        case let .SwapCols(i, j):
            A.swapCols(i, j)
        }
    }
    
    func apply(to A: inout RowOperationMatrix<R>) {
        switch self {
        case let .AddRow(i, j, r):
            A.addRow(at: i, to: j, multipliedBy: r)
        case let .MulRow(i, r):
            A.multiplyRow(at: i, by: r)
        case let .SwapRows(i, j):
            A.swapRows(i, j)
        default:
            break
        }
    }
    
    func apply(to A: inout ColOperationMatrix<R>) {
        switch self {
        case let .AddCol(i, j, r):
            A.addCol(at: i, to: j, multipliedBy: r)
        case let .MulCol(i, r):
            A.multiplyCol(at: i, by: r)
        case let .SwapCols(i, j):
            A.swapCols(i, j)
        default:
            break
        }
    }
}
