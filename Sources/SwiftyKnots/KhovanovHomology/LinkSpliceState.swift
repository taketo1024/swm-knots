//
//  LinkSpliceState.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation

public struct LinkSpliceState: Equatable, Comparable, Hashable, CustomStringConvertible {
    // MEMO (bits: 5, len: 5) <-> 00101 <-> [1, 0, 1, 0, 0]
    private let bits: Int // in binary
    public let length: Int
    public let degree: Int
    
    private init(_ bits: Int, _ length: Int) {
        self.bits = bits
        self.length = length
        self.degree = {
            var v = bits
            var d = 0
            while v != 0 {
                if v & 1 == 1 {
                    d += 1
                }
                v >>= 1
            }
            return d
        }()
    }
    
    public var enumerated: [(index: Int, bit: Int)] {
        return (0 ..< length).map{ i in (i, bits >> i & 1)}
    }
    
    public func diff(_ s: LinkSpliceState) -> (index: Int, sign: Int) {
        assert( (self.degree - s.degree).abs == 1 )
        
        var b1 = self.bits
        var b2 = s.bits
        var sign = 1
        
        for i in (0 ..< length) {
            if b1 & 1 != b2 & 1 {
                return (i, sign)
            }
            
            if b1 & 1 == 1 {
                sign *= (-1)
            }
            b1 >>= 1
            b2 >>= 1
        }
        
        fatalError()
    }
    
    public static func all(_ n: Int) -> [LinkSpliceState] {
        return (0 ..< 2.pow(n)).map{ LinkSpliceState($0, n) }.sorted()
    }
    
    public static func ==(a: LinkSpliceState, b: LinkSpliceState) -> Bool {
        return (a.bits, a.length) == (b.bits, b.length)
    }
    
    public static func <(a: LinkSpliceState, b: LinkSpliceState) -> Bool {
        return a.degree < b.degree || (a.degree == b.degree && a.bits > b.bits)
    }
    
    public var hashValue: Int {
        return bits
    }
    
    public var description: String {
        let str = String(bits, radix: 2)
        return Array(repeating: "0", count: length - str.count) + str
    }
}

public extension Link {
    public func spliced(by state: LinkSpliceState) -> Link {
        var L = self.copy()
        for (i, s) in state.enumerated {
            if s == 0 {
                L.spliceA(at: i)
            } else {
                L.spliceB(at: i)
            }
        }
        return L
    }
}
