//
//  MatrixGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol MatrixGroup: Group {
    associatedtype Size: _Int
    associatedtype CoeffField: Field
    init(_ g: SquareMatrix<Size, CoeffField>)
    
    var size: Int { get }
    var matrix: SquareMatrix<Size, CoeffField> { get }
    var asGL: GeneralLinearGroup<Size, CoeffField> { get }
    
    var determinant: CoeffField { get }
    var trace: CoeffField { get }
    
    static func contains(_ g: GeneralLinearGroup<Size, CoeffField>) -> Bool
    static func *(a: CoeffField, b: Self) -> Self
    static func *(a: Self, b: CoeffField) -> Self
}

public extension MatrixGroup {
    public init(grid: [CoeffField]) {
        self.init(Matrix(grid: grid))
    }
    
    public init(generator g: (Int, Int) -> CoeffField) {
        self.init(Matrix(generator: g))
    }
    
    public var size: Int {
        return matrix.rows
    }
    
    public static var identity: Self {
        return Self( .identity )
    }
    
    public var inverse: Self {
        return Self(matrix.inverse!)
    }
    
    public var determinant: CoeffField {
        return matrix.determinant
    }
    
    public var trace: CoeffField {
        return matrix.trace
    }
    
    public var transposed: Self {
        return Self( matrix.transposed )
    }
    
    public var asGL: GeneralLinearGroup<Size, CoeffField> {
        return GeneralLinearGroup( matrix )
    }
    
    public static func *(a: Self, b: Self) -> Self {
        return Self( a.matrix * b.matrix )
    }
    
    public static func *(a: CoeffField, b: Self) -> Self {
        assert(a.isInvertible)
        return Self( a * b.matrix )
    }
    
    public static func *(a: Self, b: CoeffField) -> Self {
        assert(b.isInvertible)
        return Self( a.matrix * b )
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

public extension MatrixGroup where CoeffField == ComplexNumber {
    public var adjoint: Self {
        return Self(matrix.adjoint)
    }
    
    // A + iB -> (A, -B; B, A)
    public func asReal<m: _Int>() -> GeneralLinearGroup<m, RealNumber> {
        let n = size
        assert(m.intValue == 2 * n)
        
        let (A, B) = (matrix.realPart, matrix.imaginaryPart)
        
        return GeneralLinearGroup<m, RealNumber> { (i, j) in
            if i < n, j < n {
                return A[i, j]
            } else if i < n, j >= n {
                return -B[i, j - n]
            } else if i >= n, j < n {
                return B[i - n, j]
            } else {
                return A[i - n, j - n]
            }
        }
    }
}
