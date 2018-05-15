//
//  PolynomialIdeal.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/09/23.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol PolynomialTP {
    associatedtype CoeffRing: Ring
    associatedtype x: Indeterminate
    typealias PolynomialType = Polynomial<CoeffRing, x>
    static var value: PolynomialType { get }
}

public protocol IrrPolynomialTP: PolynomialTP {}

// memo: Supports only Field-coeffs.
public struct PolynomialIdeal<p: PolynomialTP>: EuclideanIdeal where p.CoeffRing: Field {
    public typealias CoeffRing = p.CoeffRing
    public typealias Super = Polynomial<CoeffRing, p.x>
    public static var mod: Polynomial<CoeffRing, p.x> {
        return p.value
    }
}

extension PolynomialIdeal: MaximalIdeal where p: IrrPolynomialTP {}
