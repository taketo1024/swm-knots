//
//  MIndex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct IntList: Hashable, Comparable, CustomStringConvertible {
    internal let list: [Int]
    public init(_ list: Int ...) {
        self.init(list)
    }
    
    public init(_ list: [Int]) {
        // TODO trim last 0s.
        self.list = list
    }
    
    public init(_ list: [Int : Int]) {
        let n = (list.keys.max() ?? -1) + 1
        self.list = (0 ..< n).map{ list[$0] ?? 0 }
    }
    
    public subscript(i: Int) -> Int {
        return (i < list.count) ? list[i] : 0
    }
    
    public static var empty: IntList {
        return IntList([])
    }
    
    public var total: Int {
        return list.sumAll()
    }
    
    public var length: Int {
        return list.count
    }
    
    public func permuted(by p: Permutation) -> IntList {
        let indices = self.list.enumerated().map{ (i, j) in (p[i], j)}
        return IntList(Dictionary(pairs: indices))
    }
    
    public static func *(I: IntList, J: IntList) -> IntList {
        let l = max(I.length, J.length)
        return IntList( (0 ..< l).map{ i in I[i] + J[i] } )
    }
    
    public static func ==(I: IntList, J: IntList) -> Bool {
        return I.list == J.list
    }
    
    // e.g. (2, 1, 3) -> 2 + (1 * p) + (3 * p^2)
    public var hashValue: Int {
        let p = 31
        return list.reversed().reduce(0) { (sum, next) -> Int in
            p &* sum &+ next
        }
    }
    
    // lex order
    public static func <(I: IntList, J: IntList) -> Bool {
        return I.list.lexicographicallyPrecedes(J.list)
    }
    
    public var description: String {
        return "(\( list.map{ String($0) }.joined(separator: ", ")))"
    }
}
