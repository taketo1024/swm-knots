//
//  AsVectorSpace.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

// a Field considered as a 1-dim VectorSpace over itself.
public struct AsVectorSpace<K: Field>: FiniteDimVectorSpace {
    public typealias CoeffRing = K
    
    public let value: K
    public init(_ x: K) {
        self.value = x
    }
    
    public static var dim: Int {
        return 1
    }
    
    public static var standardBasis: [AsVectorSpace<K>] {
        return [AsVectorSpace(.identity)]
    }
    
    public var standardCoordinates: [K] {
        return [value]
    }
    
    public static var zero: AsVectorSpace<K> {
        return AsVectorSpace(.zero)
    }
    
    public static func ==(lhs: AsVectorSpace<K>, rhs: AsVectorSpace<K>) -> Bool {
        return lhs.value == rhs.value
    }
    
    public static func +(a: AsVectorSpace<K>, b: AsVectorSpace<K>) -> AsVectorSpace<K> {
        return AsVectorSpace(a.value + b.value)
    }
    
    public static prefix func -(x: AsVectorSpace<K>) -> AsVectorSpace<K> {
        return AsVectorSpace(-x.value)
    }
    
    public static func *(m: AsVectorSpace<K>, r: K) -> AsVectorSpace<K> {
        return AsVectorSpace(m.value * r)
    }
    
    public static func *(r: K, m: AsVectorSpace<K>) -> AsVectorSpace<K> {
        return AsVectorSpace(r * m.value)
    }
    
    public var hashValue: Int {
        return value.hashValue
    }
    
    public var description: String {
        return value.description
    }
}
