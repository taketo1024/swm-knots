//
//  OrthogonalLieAlgebra.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct OrthogonalLieAlgebra<n: _Int>: MatrixLieAlgebra {
    public typealias CoeffRing   = RealNumber
    public typealias ElementRing = RealNumber

    public let matrix: SquareMatrix<n, RealNumber>
    public init(_ matrix: SquareMatrix<n, RealNumber>) {
        self.matrix = matrix
    }

    public static func contains(_ X: GeneralLinearLieAlgebra<n, RealNumber>) -> Bool {
        return X.matrix.isSkewSymmetric
    }
    
    public static var symbol: String  {
        return "o(\(n.intValue))"
    }
}


