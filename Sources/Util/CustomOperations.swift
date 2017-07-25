//
//  CustomOperations.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/22.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

precedencegroup ExponentiativePrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator **: ExponentiativePrecedence

infix operator ∩: MultiplicationPrecedence
infix operator ∪: MultiplicationPrecedence
infix operator ⨯: MultiplicationPrecedence
