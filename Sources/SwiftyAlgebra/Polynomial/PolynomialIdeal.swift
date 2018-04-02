//
//  PolynomialIdeal.swift
//  SwiftyAlgebra
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
    public typealias R = p.CoeffRing
    public typealias CoeffRing = R
    public typealias Super = Polynomial<R>
    
    public static var generator: Polynomial<R> {
        return p.value
    }
    
    public let a: Polynomial<R>
    
    public init(_ a: Polynomial<R>) {
        self.a = a
    }
    
    public var asSuper: Polynomial<R> {
        return a
    }
}

public protocol _IrreduciblePolynomial: _Polynomial {}

extension PolynomialIdeal: MaximalIdeal where p: _IrreduciblePolynomial {}
