//
//  UnitaryGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct UnitaryGroup<n: _Int>: MatrixSubgroup {
    public typealias Super = GeneralLinearGroup<n, ComplexNumber>
    
    private let g: SquareMatrix<n, ComplexNumber>
    public init(_ g: SquareMatrix<n, ComplexNumber>) { self.g = g }
    public var asMatrix: SquareMatrix<n, ComplexNumber> { return g }
    
    public static func contains(_ g: GeneralLinearGroup<n, ComplexNumber>) -> Bool {
        return g * g.adjoint == .identity
    }
    
    public static var symbol: String  {
        return "U(\(n.intValue))"
    }
}

public struct SpecialUnitaryGroup<n: _Int>: MatrixSubgroup {
    public typealias Super = UnitaryGroup<n>
    
    private let g: SquareMatrix<n, ComplexNumber>
    public init(_ g: SquareMatrix<n, ComplexNumber>) { self.g = g }
    public var asMatrix: SquareMatrix<n, ComplexNumber> { return g }
    
    public static func contains(_ g: UnitaryGroup<n>) -> Bool {
        return SpecialLinearGroup.contains(g.asSuper)
    }
    
    public static func contains(_ g: GeneralLinearGroup<n, ComplexNumber>) -> Bool {
        return UnitaryGroup.contains(g) && SpecialLinearGroup.contains(g)
    }
}

