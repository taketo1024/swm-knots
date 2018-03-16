//
//  OrthogonalGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct OrthogonalGroup<n: _Int>: MatrixGroup {
    public let matrix: SquareMatrix<n, RealNumber>
    public init(_ matrix: SquareMatrix<n, RealNumber>) {
        self.matrix = matrix
    }

    public static func contains(_ g: GeneralLinearGroup<n, RealNumber>) -> Bool {
        return g * g.transposed == .identity
    }
    
    public static var symbol: String  {
        return "O(\(n.intValue))"
    }
}

public struct SpecialOrthogonalGroup<n: _Int>: MatrixGroup {
    public let matrix: SquareMatrix<n, RealNumber>
    public init(_ matrix: SquareMatrix<n, RealNumber>) {
        self.matrix = matrix
    }

    public static func contains(_ g: GeneralLinearGroup<n, RealNumber>) -> Bool {
        return OrthogonalGroup.contains(g) && SpecialLinearGroup.contains(g)
    }
    
    public static var symbol: String  {
        return "SO(\(n.intValue))"
    }
}

