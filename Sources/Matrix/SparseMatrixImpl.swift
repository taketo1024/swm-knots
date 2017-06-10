//
//  GridMatrixImpl.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class _SparseMatrixImpl<R: Ring>: _MatrixImpl<R> {
    public required init(_ rows: Int, _ cols: Int, _ g: (Int, Int) -> R) {
        super.init(rows, cols, g)
    }
    
    public override func copy() -> Self {
        fatalError()
//        return type(of: self).init(rows, cols, grid)
    }
    
    public override subscript(i: Int, j: Int) -> R {
        get { fatalError() }
        set { fatalError() }
    }
    
    public override func equals(_ b: _MatrixImpl<R>) -> Bool {
        assert((rows, cols) == (b.rows, b.cols), "Mismatching matrix size.")
        fatalError()
    }
    
    public override func multiplyRow(at i0: Int, by r: R) {
        fatalError()
    }
    
    public override func multiplyCol(at j0: Int, by r: R) {
        fatalError()
    }
    
    public override func addRow(at i0: Int, to i1: Int, multipliedBy r: R) {
        fatalError()
    }
    
    public override func addCol(at j0: Int, to j1: Int, multipliedBy r: R) {
        fatalError()
    }
    
    public override func swapRows(_ i0: Int, _ i1: Int) {
        fatalError()
    }
    
    public override func swapCols(_ j0: Int, _ j1: Int) {
        fatalError()
    }
}
