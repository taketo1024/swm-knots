//
//  AlgebraicExtension.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias AlgebraicExtension<K: Field, p: _IrreduciblePolynomial> = QuotientRing<Polynomial<K>, PolynomialIdeal<p>> where K == p.CoeffRing
