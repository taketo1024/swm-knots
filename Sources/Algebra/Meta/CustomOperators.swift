//
//  CustomOperations.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/22.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

// https://en.wikipedia.org/wiki/Mathematical_operators_and_symbols_in_Unicode

import Foundation

precedencegroup ExponentiativePrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator **: ExponentiativePrecedence
infix operator /%: MultiplicationPrecedence
infix operator ∩: MultiplicationPrecedence
infix operator ∪: MultiplicationPrecedence
infix operator ∘: MultiplicationPrecedence
infix operator ×: MultiplicationPrecedence
infix operator ⊕: MultiplicationPrecedence
infix operator ⊗: MultiplicationPrecedence
infix operator ∧: MultiplicationPrecedence
infix operator ∨: MultiplicationPrecedence
