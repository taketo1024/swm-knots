//
//  GL.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct GeneralLinearGroup<n: _Int, K: Field>: MatrixGroup {
    public let matrix: SquareMatrix<n, K>
    public init(_ matrix: SquareMatrix<n, K>) {
        self.matrix = matrix
    }

    public static func contains(_ g: GeneralLinearGroup<n, K>) -> Bool {
        return true
    }
    
    public static var symbol: String  {
        return "GL(\(n.intValue), \(K.symbol))"
    }
}

public struct SpecialLinearGroup<n: _Int, K: Field>: MatrixGroup {
    public let matrix: SquareMatrix<n, K>
    public init(_ matrix: SquareMatrix<n, K>) {
        self.matrix = matrix
    }

    public static func contains(_ g: GeneralLinearGroup<n, K>) -> Bool {
        return g.determinant == .identity
    }
    
    public static var symbol: String  {
        return "SL(\(n.intValue), \(K.symbol))"
    }
}
