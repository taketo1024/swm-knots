//
//  UnitaryLieAlgebra.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct UnitaryLieAlgebra<n: _Int>: MatrixLieAlgebra {
    public typealias CoeffRing   = RealNumber // MEMO: not a C-vec sp.
    public typealias ElementRing = ComplexNumber
    
    public let matrix: SquareMatrix<n, ComplexNumber>
    public init(_ matrix: SquareMatrix<n, ComplexNumber>) {
        self.matrix = matrix
    }

    public static func contains(_ X: GeneralLinearLieAlgebra<n, ComplexNumber>) -> Bool {
        return X.matrix.isSkewHermitian
    }
    
    public static var symbol: String  {
        return "u(\(n.intValue))"
    }
}

public struct SpecialUnitaryLieAlgebra<n: _Int>: MatrixLieAlgebra {
    public typealias CoeffRing   = RealNumber // MEMO: not a C-vec sp.
    public typealias ElementRing = ComplexNumber

    public let matrix: SquareMatrix<n, ComplexNumber>
    public init(_ matrix: SquareMatrix<n, ComplexNumber>) {
        self.matrix = matrix
    }

    public static func contains(_ g: GeneralLinearLieAlgebra<n, ComplexNumber>) -> Bool {
        return UnitaryLieAlgebra.contains(g) && SpecialLinearLieAlgebra.contains(g)
    }
}
