//
//  MIndex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct MIndex: Hashable, Comparable, CustomStringConvertible {
    internal let indices: [Int]
    public init(_ indices: Int ...) {
        self.init(indices)
    }
    
    public init(_ indices: [Int]) {
        // TODO trim last 0s.
        self.indices = indices
    }
    
    public subscript(i: Int) -> Int {
        return (i < indices.count) ? indices[i] : 0
    }
    
    public static var zero: MIndex {
        return MIndex([])
    }
    
    public var degree: Int {
        return indices.sumAll()
    }
    
    public var length: Int {
        return indices.count
    }
    
    public static func *(I: MIndex, J: MIndex) -> MIndex {
        let l = max(I.length, J.length)
        return MIndex( (0 ..< l).map{ i in I[i] + J[i] } )
    }
    
    public static func ==(I: MIndex, J: MIndex) -> Bool {
        return I.indices == J.indices
    }
    
    // e.g. (2, 1, 3) -> 2 + (1 * p) + (3 * p^2)
    public var hashValue: Int {
        let p = 31
        return indices.reversed().reduce(0) { (sum, next) -> Int in
            p &* sum &+ next
        }
    }
    
    // lex order
    public static func <(I: MIndex, J: MIndex) -> Bool {
        return I.indices.lexicographicallyPrecedes(J.indices)
    }
    
    public var description: String {
        return "(\( indices.map{ String($0) }.joined(separator: ", ")))"
    }
}
