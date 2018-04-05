//
//  PolynomialIdeal.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/09/23.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _Polynomial {
    associatedtype CoeffRing: Ring
    static var value: Polynomial<CoeffRing> { get }
}

// memo: Supports only Field-coeffs.
public struct PolynomialIdeal<p: _Polynomial>: EuclideanIdeal where p.CoeffRing: Field {
    public typealias CoeffRing = p.CoeffRing
    public typealias Super = Polynomial<CoeffRing>
    public static var mod: Polynomial<CoeffRing> {
        return p.value
    }
}

public protocol _IrreduciblePolynomial: _Polynomial {}

extension PolynomialIdeal: MaximalIdeal where p: _IrreduciblePolynomial {}
