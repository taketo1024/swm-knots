//
//  UnitaryGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct UnitaryGroup<n: _Int>: MatrixGroup {
    public let matrix: SquareMatrix<n, ComplexNumber>
    public init(_ matrix: SquareMatrix<n, ComplexNumber>) {
        self.matrix = matrix
    }

    public static func contains(_ g: GeneralLinearGroup<n, ComplexNumber>) -> Bool {
        return g.matrix.isUnitary
    }
    
    public static var symbol: String  {
        return "U(\(n.intValue))"
    }
}

public struct SpecialUnitaryGroup<n: _Int>: MatrixGroup {
    public let matrix: SquareMatrix<n, ComplexNumber>
    public init(_ matrix: SquareMatrix<n, ComplexNumber>) {
        self.matrix = matrix
    }

    public static func contains(_ g: GeneralLinearGroup<n, ComplexNumber>) -> Bool {
        return UnitaryGroup.contains(g) && SpecialLinearGroup.contains(g)
    }
}

