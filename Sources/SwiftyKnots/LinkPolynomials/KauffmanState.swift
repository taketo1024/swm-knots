//
//  LinkSpliceState.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation

public struct KauffmanState: Equatable, Comparable, Hashable, CustomStringConvertible {
    public let bits: [UInt8]
    public init(_ bits: [UInt8]) {
        self.bits = bits
    }
    
    public var length: Int {
        return bits.count
    }
    
    public var count0: Int {
        return bits.count{ $0 == 0 }
    }
    
    public var count1: Int {
        return bits.count{ $0 == 1 }
    }
    
    public var degree: Int {
        return count1
    }
    
    public var next: [(sign: Int, state: KauffmanState)] {
        return (0 ..< length).compactMap { i -> (Int, KauffmanState)? in
            if bits[i] == 0 {
                let sgn = (-1).pow( bits[0 ..< i].count{ $0 == 1 } )
                let next = bits.replaced(at: i, with: 1)
                return (sgn, KauffmanState(next))
            } else {
                return nil
            }
        }
    }
    
    public static func all(_ n: Int) -> [KauffmanState] {
        return (0 ..< n).reduce([[]]) { (res, _) -> [[UInt8]] in
            res.map{ $0 + [0] } + res.map{ $0 + [1] }
        }.map{ KauffmanState($0) }.sorted()
    }
    
    public static func ==(a: KauffmanState, b: KauffmanState) -> Bool {
        return a.bits == b.bits
    }
    
    public static func <(a: KauffmanState, b: KauffmanState) -> Bool {
        return a.degree < b.degree || (a.degree == b.degree && b.bits.lexicographicallyPrecedes(a.bits))
    }
    
    public var hashValue: Int {
        return bits.reduce(0) { (res, b) in 2 &* res &+ Int(b) }
    }
    
    public var description: String {
        return bits.map{ "\($0)" }.joined()
    }
}

public extension Link {
    /*
     *     \ /          \ /
     *      /      ==>  | |
     *     / \          / \
     */
    
    @discardableResult
    public mutating func splice0(at n: Int) -> Link {
        crossings[n].splice0()
        return self
    }
    
    public func spliced0(at n: Int) -> Link {
        var L = self.copy()
        L.splice0(at: n)
        return L
    }
    
    /*
     *     \ /          \_/
     *      /      ==>
     *     / \          /‾\
     */
    
    @discardableResult
    public mutating func splice1(at n: Int) -> Link {
        crossings[n].splice1()
        return self
    }
    
    public func spliced1(at n: Int) -> Link {
        var L = self.copy()
        L.splice1(at: n)
        return L
    }
    
    public func spliced(by state: KauffmanState) -> Link {
        var L = self.copy()
        for (i, b) in state.bits.enumerated() {
            if b == 0 {
                L.splice0(at: i)
            } else {
                L.splice1(at: i)
            }
        }
        return L
    }
}

extension KauffmanState: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.bits = try c.decode([UInt8].self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(bits)
    }
}
