//
//  MatrixIterator.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/10/16.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// MatrixIterator

public enum MatrixIterationDirection {
    case Rows
    case Cols
}

public struct MatrixIterator<n: _Int, m: _Int, R: Ring> : IteratorProtocol {
    private let matrix: Matrix<n, m, R>
    private let direction: MatrixIterationDirection
    private let rowRange: CountableRange<Int>
    private let colRange: CountableRange<Int>
    private let proceedLines: Bool
    private let nonZeroOnly: Bool
    
    private var current: (Int, Int)
    private var initial = true
    
    public init(_ matrix: Matrix<n, m, R>, from: (Int, Int)? = nil, direction: MatrixIterationDirection = .Rows, rowRange: CountableRange<Int>? = nil, colRange: CountableRange<Int>? = nil, proceedLines: Bool = true, nonZeroOnly: Bool = false) {
        self.matrix = matrix
        self.current = from ?? (rowRange?.lowerBound ?? 0, colRange?.lowerBound ?? 0)
        self.direction = direction
        self.rowRange = rowRange ?? (0 ..< matrix.rows)
        self.colRange = colRange ?? (0 ..< matrix.cols)
        self.proceedLines = proceedLines
        self.nonZeroOnly = nonZeroOnly
    }
    
    mutating public func next() -> MatrixComponent<R>? {
        let c = findNext(from: current, includeFirst:initial, direction: direction, rowRange: rowRange, colRange: colRange, proceedLines: proceedLines, nonZeroOnly: nonZeroOnly)
        
        if initial {
            initial = false
        }
        
        if let next = c {
            current = (next.0, next.1)
        }
        
        return c
    }
    
    internal func findNext(from: (Int, Int), includeFirst: Bool, direction: MatrixIterationDirection, rowRange: CountableRange<Int>, colRange: CountableRange<Int>, proceedLines: Bool, nonZeroOnly: Bool) -> MatrixComponent<R>? {
        if includeFirst && matrix.rows * matrix.cols > 0 {
            let a = matrix[from.0, from.1]
            if !nonZeroOnly || a != R.zero {
                return (from.0, from.1, a)
            }
        }
        
        func nextPos(_ from: (Int, Int)) -> (Int, Int)? {
            if !rowRange.contains(from.0) || !colRange.contains(from.1) {
                return nil
            }
            
            switch direction {
            case .Rows:
                switch (from.0 + 1, from.1 + 1, rowRange.upperBound, colRange.upperBound, proceedLines) {
                // within col-range
                case let (_, j, _, c, _) where j < c:
                    return (from.0, j)
                    
                // end of row, no proceeding lines
                case (_, _, _, _, false):
                    return nil
                    
                // can proceed line
                case let (i, _, r, _, _) where i < r:
                    return (i, colRange.lowerBound)
                    
                // end of range
                default:
                    return nil
                }
            case .Cols:
                switch (from.0 + 1, from.1 + 1, rowRange.upperBound, colRange.upperBound, proceedLines) {
                // within row-range
                case let (i, _, r, _, _) where i < r:
                    return (i, from.1)
                    
                // end of row, no proceeding lines
                case (_, _, _, _, false):
                    return nil
                    
                // can proceed line
                case let (_, j, _, c, _) where j < c:
                    return (rowRange.lowerBound, j)
                    
                // end of range
                default:
                    return nil
                }
            }
        }
        
        // MEMO: Tail Recursion Optimization doen't seem to work when return-type is optional.
        
        var next: (Int, Int) = from
        while let (i, j) = nextPos(next) {
            let a = matrix[i, j]
            
            if !nonZeroOnly || a != R.zero {
                return (i, j, a)
            } else {
                next = (i, j)
            }
        }
        
        return nil
    }
}
