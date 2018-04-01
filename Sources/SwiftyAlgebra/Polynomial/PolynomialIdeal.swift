//
//  PolynomialIdeal.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/09/23.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _Polynomial {
    associatedtype K: Field
    static var value: Polynomial<K> { get }
}

public protocol _IrreduciblePolynomial: _Polynomial {}

public struct PolynomialIdeal<p: _Polynomial>: EuclideanIdeal {
    public typealias K = p.K
    public typealias Super = Polynomial<K>
    
    public static var generator: Polynomial<K> {
        return p.value
    }
    
    public let a: Polynomial<K>
    
    public init(_ a: Polynomial<K>) {
        self.a = a
    }
    
    public init(_ coeffs: K...) {
        self.init(Super(coeffs: coeffs))
    }
    
    public var asSuper: Polynomial<K> {
        return a
    }
}

extension PolynomialIdeal: MaximalIdeal where p: _IrreduciblePolynomial {}

public typealias AlgebraicExtension<K, p: _IrreduciblePolynomial> = QuotientRing<Polynomial<K>, PolynomialIdeal<p>> where K == p.K
