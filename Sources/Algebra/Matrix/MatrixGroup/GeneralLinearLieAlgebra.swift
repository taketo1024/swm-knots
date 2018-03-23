//
//  GeneralLinearLieAlgebra.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/18.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct GeneralLinearLieAlgebra<n: _Int, K: Field>: MatrixLieAlgebra {
    public typealias CoeffRing   = K
    public typealias ElementRing = K

    public let matrix: SquareMatrix<n, K>
    public init(_ matrix: SquareMatrix<n, K>) {
        self.matrix = matrix
    }
    
    public static func contains(_ g: GeneralLinearLieAlgebra<n, K>) -> Bool {
        return true
    }
    
    public static var dim: Int {
        let n = Size.intValue
        return n * n
    }
    
    public static var standardBasis: [GeneralLinearLieAlgebra<n, K>] {
        let n = Size.intValue
        return (0 ..< n).flatMap { i in
            (0 ..< n).map { j in GeneralLinearLieAlgebra(Matrix.unit(i, j)) }
        }
    }
    
    public var standardCoordinates: [CoeffRing] {
        let n = size
        return (0 ..< n).flatMap { i in
            (0 ..< n).map { j in matrix[i, j] }
        }
    }
    
    public static var symbol: String  {
        return "gl(\(n.intValue), \(K.symbol))"
    }
}

public struct SpecialLinearLieAlgebra<n: _Int, K: Field>: MatrixLieAlgebra {
    public typealias CoeffRing   = K
    public typealias ElementRing = K

    public let matrix: SquareMatrix<n, K>
    public init(_ matrix: SquareMatrix<n, K>) {
        self.matrix = matrix
    }
    
    public static func contains(_ g: GeneralLinearLieAlgebra<n, K>) -> Bool {
        return g.matrix.trace == .zero
    }
    
    public static var dim: Int {
        let n = Size.intValue
        return n * n - 1
    }
    
    public static var standardBasis: [SpecialLinearLieAlgebra<n, K>] {
        let n = Size.intValue
        return
            (0 ..< n).flatMap { i -> [SpecialLinearLieAlgebra<n, K>] in
                (0 ..< n).flatMap { j -> SpecialLinearLieAlgebra<n, K>? in
                    (i != j) ? SpecialLinearLieAlgebra(Matrix.unit(i, j)) : nil
                }
            }
            +
            (0 ..< n - 1).map { i -> SpecialLinearLieAlgebra<n, K> in
                SpecialLinearLieAlgebra(Matrix.unit(i, i) - Matrix.unit(n - 1, n - 1))
            }
    }
    
    public var standardCoordinates: [CoeffRing] {
        let n = size
        return
            (0 ..< n).flatMap { i -> [CoeffRing] in
                (0 ..< n).flatMap { j -> CoeffRing? in
                    (i != j) ? matrix[i, j] : nil
                }
            }
            +
            (0 ..< n - 1).map { i in matrix[i, i] }
    }
    
    public static var symbol: String  {
        return "sl(\(n.intValue), \(K.symbol))"
    }
}
