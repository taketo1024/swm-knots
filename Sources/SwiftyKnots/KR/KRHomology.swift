//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/10.
//

import SwiftyMath
import SwiftyHomology

public struct _x: PolynomialIndeterminate {
    public static let degree = 2
    public static var symbol = "x"
}
public typealias _xn = InfiniteVariatePolynomialIndeterminates<_x>

public struct KRHomology<R: Ring> {
    public typealias Grading = GridCoords<_3>
    public typealias EdgeRing = MultivariatePolynomial<_xn, R>
    public typealias BaseModule = LinearCombination<MultivariatePolynomialGenerator<_xn>, R>
    
}
