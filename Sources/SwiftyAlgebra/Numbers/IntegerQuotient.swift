//
//  IntegerQuotient.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/01.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias 𝐙₂ = IntegerQuotientRing<_2>

// MEMO waiting for parametrized extension.
// see: https://github.com/apple/swift/blob/master/docs/GenericsManifesto.md#parameterized-extensions

public protocol _IntegerIdeal: EuclideanIdeal {
    associatedtype _n: _Int
}

public struct IntegerIdeal<n: _Int>: _IntegerIdeal {
    public typealias Super = 𝐙
    public typealias _n = n
    
    public static var generator: 𝐙 {
        return n.intValue
    }
    
    public let a: 𝐙
    
    public init(_ a: 𝐙) {
        self.a = a
    }
    
    public var asSuper: 𝐙 {
        return a
    }
}

extension IntegerIdeal: MaximalIdeal where n: _Prime {}

public typealias IntegerQuotientRing<n: _Int> = QuotientRing<𝐙, IntegerIdeal<n>>

extension IntegerQuotientRing: FiniteSet, ExpressibleByIntegerLiteral where Base == 𝐙, Sub: _IntegerIdeal {
    public typealias IntegerLiteralType = Int
    
    public init(integerLiteral n: Int) {
        self.init(n)
    }

    public static var allElements: [QuotientRing<Base, Sub>] {
        return (0 ..< Sub._n.intValue).map{ QuotientRing($0) }
    }
    
    public static var countElements: Int {
        return Sub._n.intValue
    }
}
