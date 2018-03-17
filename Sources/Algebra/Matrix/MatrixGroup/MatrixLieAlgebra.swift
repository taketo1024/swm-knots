//
//  LieAlgebra.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol LieAlgebra: VectorSpace {
    func bracket(_ Y: Self) -> Self
}

public func bracket<𝔤: LieAlgebra>(_ X: 𝔤, _ Y: 𝔤) -> 𝔤 {
    return X.bracket(Y)
}

public protocol MatrixLieAlgebra: LieAlgebra {
    associatedtype Size: _Int
    
    init(_ g: SquareMatrix<Size, CoeffRing>)
    var size: Int { get }
    var matrix: SquareMatrix<Size, CoeffRing> { get }
    
    static func contains(_ g: GeneralLinearLieAlgebra<Size, CoeffRing>) -> Bool
}

public extension MatrixLieAlgebra {
    public init(grid: [CoeffRing]) {
        self.init(Matrix(grid: grid))
    }
    
    public init(generator g: (Int, Int) -> CoeffRing) {
        self.init(Matrix(generator: g))
    }
    
    public var size: Int {
        return matrix.rows
    }
    
    public static var zero: Self {
        return Self( .zero )
    }
    
    public static func +(a: Self, b: Self) -> Self {
        return Self(a.matrix + b.matrix)
    }
    
    public static prefix func -(a: Self) -> Self {
        return Self(-a.matrix)
    }
    
    public static func *(a: Self, b: CoeffRing) -> Self {
        return Self( a.matrix * b )
    }
    
    public static func *(a: CoeffRing, b: Self) -> Self {
        return Self( a * b.matrix )
    }
    
    public func bracket(_ b: Self) -> Self {
        let (X, Y) = (self.matrix, b.matrix)
        return Self(X * Y - Y * X)
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.matrix == rhs.matrix
    }
    
    public var hashValue: Int {
        return matrix.hashValue
    }
    
    public var description: String {
        return matrix.description
    }
    
    public var detailDescription: String {
        return matrix.detailDescription
    }
}
