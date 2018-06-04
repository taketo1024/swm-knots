//
//  LinkSpliceState.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public struct KauffmanState: Equatable, Comparable, Hashable, CustomStringConvertible {
    /*
     *     \ /     0     \ /
     *      /     ===>   | |
     *     / \           / \
     *
     *
     *     \ /     1     \_/
     *      /     ===>
     *     / \           /‾\
     */
    
    public enum Bit: Int, Codable, CustomStringConvertible {
        case O, I
        
        public var description: String {
            return (self == .O) ? "0" : "1"
        }
    }
    
    internal var bits: [Int : Bit]
    public init(_ bits: [Int : Bit]) {
        self.bits = bits
    }
    
    public subscript(i: Int) -> Bit {
        get {
            return bits[i]!
        } set {
            bits[i] = newValue
        }
    }
    
    public mutating func unset(_ i: Int) {
        bits[i] = nil
    }
    
    public var length: Int {
        return bits.count
    }
    
    public var count0: Int {
        return bits.count{ $0.value == .O }
    }
    
    public var count1: Int {
        return bits.count{ $0.value == .I }
    }
    
    public var degree: Int {
        return count1
    }
    
    public static func ==(a: KauffmanState, b: KauffmanState) -> Bool {
        return a.bits == b.bits
    }
    
    public static func <(a: KauffmanState, b: KauffmanState) -> Bool {
        func indices(_ a: KauffmanState) -> [Int] {
            return a.bits.compactMap{ $0.value == .O ? $0.key : nil }
        }
        return (a.degree < b.degree) || (a.degree == b.degree && indices(a) < indices(b))
    }
    
    public var hashValue: Int {
        return bits.reduce(0) { (res, e) in
            res &+ (e.value.rawValue &<< e.key)
        }
    }
    
    public var description: String {
        if Set(bits.keys) == Set( 0 ..< length ) {
            return "(" + (0 ..< length).map{ i in "\(self[i])" }.joined() + ")"
        } else {
            return "(" + bits.sorted{ $0.key }.map{ (i, a) in "\(i):\(a)" }.joined(separator: ", ") + ")"
        }
    }
}

public extension Link {
    public var allStates: [KauffmanState] {
        let indices = self.crossings.enumerated().compactMap{ (i, c) in c.isCrossing ? i : nil }
        let all: [[(Int, KauffmanState.Bit)]] = indices.reduce([[]]) { (res, i) in
            res.map{ $0.appended((i, .O)) } + res.map{ $0.appended((i, .I)) }
        }
        return all.map { pairs in KauffmanState(Dictionary(pairs: pairs))}.sorted()
    }
    
    @discardableResult
    public mutating func splice(at i: Int, by mode: KauffmanState.Bit) -> Link {
        switch mode {
        case .O: crossings[i].splice0()
        case .I: crossings[i].splice1()
        }
        return self
    }
    
    public func spliced(at i: Int, by mode: KauffmanState.Bit) -> Link {
        var L = self.copy(name: "\(name)\(Format.sub(mode.description))")
        return L.splice(at: i, by: mode)
    }

    public func spliced(by state: KauffmanState) -> Link {
        var L = self.copy()
        for (i, s) in state.bits {
            L.splice(at: i, by: s)
        }
        return L
    }
    
    public func splicedPair(at i: Int) -> (Link, Link) {
        return (self.spliced(at: i, by: .O), self.spliced(at: i, by: .I))
    }
}

extension KauffmanState: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        do {
            let a = try c.decode([Int].self)
            self.bits = Dictionary(pairs: a.enumerated().map{ (i, v) in (i, Bit(rawValue: v)!) })
        } catch {
            self.bits = try c.decode([Int : Bit].self)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        if bits.keys.sorted() == (0 ..< bits.count).toArray() {
            try c.encode(bits.sorted{ $0.key }.map{ $0.value.rawValue })
        } else {
            try c.encode(bits)
        }
    }
}
