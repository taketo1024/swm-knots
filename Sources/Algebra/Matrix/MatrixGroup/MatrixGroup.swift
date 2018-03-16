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
    var asMatrix: SquareMatrix<Size, CoeffField> { get }
    var asGL: GeneralLinearGroup<Size, CoeffField> { get }
    
    var determinant: CoeffField { get }
    var trace: CoeffField { get }
}

public extension MatrixGroup {
    public init(grid: [CoeffField]) {
        self.init(Matrix(grid: grid))
    }
    
    public init(generator g: (Int, Int) -> CoeffField) {
        self.init(Matrix(generator: g))
    }
    
    public var size: Int {
        return asMatrix.rows
    }
    
    public static var identity: Self {
        return Self( .identity )
    }
    
    public var inverse: Self {
        return Self(asMatrix.inverse!)
    }
    
    public var determinant: CoeffField {
        return asMatrix.determinant
    }
    
    public var trace: CoeffField {
        return asMatrix.trace
    }
    
    public var transposed: Self {
        return Self( asMatrix.transposed )
    }
    
    public var asGL: GeneralLinearGroup<Size, CoeffField> {
        return GeneralLinearGroup( asMatrix )
    }
    
    public static func *(a: Self, b: Self) -> Self {
        return Self( a.asMatrix * b.asMatrix )
    }
    
    public static func *(a: CoeffField, b: Self) -> Self {
        assert(a.isInvertible)
        return Self( a * b.asMatrix )
    }
    
    public static func *(a: Self, b: CoeffField) -> Self {
        assert(b.isInvertible)
        return Self( a.asMatrix * b )
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.asMatrix == rhs.asMatrix
    }
    
    public var hashValue: Int {
        return asMatrix.hashValue
    }
    
    public var description: String {
        return asMatrix.description
    }
    
    public var detailDescription: String {
        return asMatrix.detailDescription
    }
}

public extension MatrixGroup where CoeffField == ComplexNumber {
    public var adjoint: Self {
        return Self(asMatrix.adjoint)
    }
    
    // A + iB -> (A, -B; B, A)
    public func asReal<m: _Int>() -> GeneralLinearGroup<m, RealNumber> {
        let n = size
        assert(m.intValue == 2 * n)
        
        let C = self.asMatrix
        let (A, B) = (C.realPart, C.imaginaryPart)
        
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

public protocol MatrixSubgroup: MatrixGroup, Subgroup where Super: MatrixGroup, Super.Size == Size, Super.CoeffField == CoeffField {}

public extension MatrixSubgroup {
    public init(_ g: Super) {
        self.init(g.asMatrix)
    }
    
    public init(grid: [CoeffField]) {
        self.init(Matrix(grid: grid))
    }
    
    public init(generator g: (Int, Int) -> CoeffField) {
        self.init(Matrix(generator: g))
    }
    
    public var asSuper: Super {
        return Super(asMatrix)
    }
    
    public static var identity: Self {
        return Self( .identity )
    }
    
    public var inverse: Self {
        return Self(asMatrix.inverse!)
    }
    
    public static func *(a: Self, b: Self) -> Self {
        return Self( a.asMatrix * b.asMatrix )
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.asMatrix == rhs.asMatrix
    }
    
    public var hashValue: Int {
        return asMatrix.hashValue
    }
    
    public var description: String {
        return asMatrix.description
    }
    
    public var detailDescription: String {
        return asMatrix.detailDescription
    }
}
