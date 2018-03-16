//
//  OrthogonalGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct OrthogonalGroup<n: _Int>: MatrixSubgroup {
    public typealias Super = GeneralLinearGroup<n, RealNumber>
    
    private let g: SquareMatrix<n, RealNumber>
    public init(_ g: SquareMatrix<n, RealNumber>) { self.g = g }
    public var asMatrix: SquareMatrix<n, RealNumber> { return g }
    
    public static func contains(_ g: GeneralLinearGroup<n, RealNumber>) -> Bool {
        return g * g.transposed == .identity
    }
}

public struct SpecialOrthogonalGroup<n: _Int>: MatrixSubgroup {
    public typealias Super = OrthogonalGroup<n>
    
    private let g: SquareMatrix<n, RealNumber>
    public init(_ g: SquareMatrix<n, RealNumber>) { self.g = g }
    public var asMatrix: SquareMatrix<n, RealNumber> { return g }
    
    public static func contains(_ g: OrthogonalGroup<n>) -> Bool {
        return SpecialLinearGroup.contains(g.asSuper)
    }
    
    public static func contains(_ g: GeneralLinearGroup<n, RealNumber>) -> Bool {
        return OrthogonalGroup.contains(g) && SpecialLinearGroup.contains(g)
    }
}

