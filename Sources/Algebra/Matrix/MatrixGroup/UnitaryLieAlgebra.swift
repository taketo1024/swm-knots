//
//  UnitaryLieAlgebra.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct UnitaryLieAlgebra<n: _Int>: MatrixLieAlgebra {
    public typealias CoeffRing   = 𝐑 // MEMO: not a C-vec sp.
    public typealias ElementRing = 𝐂
    
    public let matrix: SquareMatrix<n, 𝐂>
    public init(_ matrix: SquareMatrix<n, 𝐂>) {
        self.matrix = matrix
    }

    public static var dim: Int {
        let n = Size.intValue
        return n * n
    }
    
    public static var standardBasis: [UnitaryLieAlgebra<n>] {
        typealias 𝔤 = UnitaryLieAlgebra<n>
        
        let n = Size.intValue
        let E = SquareMatrix<n, ComplexNumber>.unit
        let ι = ComplexNumber.imaginaryUnit
        
        return
            (0 ..< n - 1).flatMap{ i -> [𝔤] in
                (i + 1 ..< n).map { j -> 𝔤 in
                    𝔤(E(i, j) - E(j, i))
                }
            }
            +
            (0 ..< n - 1).flatMap{ i -> [𝔤] in
                (i + 1 ..< n).map { j -> 𝔤 in
                    𝔤(ι * (E(i, j) + E(j, i)))
                }
            }
            +
            (0 ..< n).map{ i -> 𝔤 in
                𝔤(ι * E(i, i))
            }
    }
    
    public var standardCoordinates: [RealNumber] {
        let n = size
        return
            (0 ..< n - 1).flatMap{ i -> [RealNumber] in
                (i + 1 ..< n).map { j -> RealNumber in matrix[i, j].real }
            }
            +
            (0 ..< n - 1).flatMap{ i -> [RealNumber] in
                (i + 1 ..< n).map { j -> RealNumber in matrix[i, j].imaginary }
            }
            +
            (0 ..< n).map{ i -> RealNumber in matrix[i, i].imaginary }
    }
    
    public static func contains(_ X: GeneralLinearLieAlgebra<n, 𝐂>) -> Bool {
        return X.matrix.isSkewHermitian
    }
    
    public static var symbol: String  {
        return "u(\(n.intValue))"
    }
}

public struct SpecialUnitaryLieAlgebra<n: _Int>: MatrixLieAlgebra {
    public typealias CoeffRing   = 𝐑 // MEMO: not a C-vec sp.
    public typealias ElementRing = 𝐂

    public let matrix: SquareMatrix<n, 𝐂>
    public init(_ matrix: SquareMatrix<n, 𝐂>) {
        self.matrix = matrix
    }

    public static var dim: Int {
        let n = Size.intValue
        return n * n - 1
    }
    
    public static var standardBasis: [SpecialUnitaryLieAlgebra<n>] {
        typealias 𝔤 = SpecialUnitaryLieAlgebra<n>
        
        let n = Size.intValue
        let E = SquareMatrix<n, ComplexNumber>.unit
        let ι = ComplexNumber.imaginaryUnit
        
        return
            (0 ..< n - 1).flatMap{ i -> [𝔤] in
                (i + 1 ..< n).map { j -> 𝔤 in
                    𝔤(E(i, j) - E(j, i))
                }
            }
            +
            (0 ..< n - 1).flatMap{ i -> [𝔤] in
                (i + 1 ..< n).map { j -> 𝔤 in
                    𝔤(ι * (E(i, j) + E(j, i)))
                }
            }
            +
            (0 ..< n - 1).map{ i -> 𝔤 in
                𝔤(ι * (E(i, i) - E(n - 1, n - 1)))
            }
    }
    
    public var standardCoordinates: [RealNumber] {
        let n = size
        return
            (0 ..< n - 1).flatMap{ i -> [RealNumber] in
                (i + 1 ..< n).map { j -> RealNumber in matrix[i, j].real }
            }
            +
            (0 ..< n - 1).flatMap{ i -> [RealNumber] in
                (i + 1 ..< n).map { j -> RealNumber in matrix[i, j].imaginary }
            }
            +
            (0 ..< n - 1).map{ i -> RealNumber in matrix[i, i].imaginary }
    }
    
    public static func contains(_ g: GeneralLinearLieAlgebra<n, 𝐂>) -> Bool {
        return UnitaryLieAlgebra.contains(g) && SpecialLinearLieAlgebra.contains(g)
    }
}
