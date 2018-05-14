//
//  IntegerQuotient.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/04/01.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias 𝐙₂ = IntegerQuotientRing<_2>

// MEMO waiting for parametrized extension.
// see: https://github.com/apple/swift/blob/master/docs/GenericsManifesto.md#parameterized-extensions

public protocol _IntegerIdeal: EuclideanIdeal {
    associatedtype n: _Int
}

public struct IntegerIdeal<n: _Int>: _IntegerIdeal {
    public typealias Super = 𝐙
    public static var mod: 𝐙 {
        return n.intValue
    }
}

extension IntegerIdeal: MaximalIdeal where n: _Prime {}

public typealias IntegerQuotientRing<n: _Int> = QuotientRing<𝐙, IntegerIdeal<n>>

extension IntegerQuotientRing: FiniteSetType where Base == 𝐙, Sub: _IntegerIdeal {
    public static var allElements: [QuotientRing<Base, Sub>] {
        return (0 ..< Sub.mod).map{ QuotientRing($0) }
    }
    
    public static var countElements: Int {
        return Sub.mod
    }
}

extension IntegerQuotientRing: Codable where Base == 𝐙, Sub: _IntegerIdeal {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        try self.init(c.decode(𝐙.self))
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(self.representative)
    }
}
