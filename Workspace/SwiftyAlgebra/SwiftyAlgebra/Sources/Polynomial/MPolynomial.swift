//
//  MPolynomial.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

import Foundation

public struct MIndex: Hashable, Comparable, CustomStringConvertible {
    internal let indices: [Int]
    public init(_ indices: [Int]) {
        assert(indices.count == 0 || indices.last! != .zero)
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
    
    public static func *(lhs: MIndex, rhs: MIndex) -> MIndex {
        let l = max(lhs.length, rhs.length)
        return MIndex( (0 ..< l).map{ i in lhs[i] + rhs[i] } )
    }
    
    public static func ==(lhs: MIndex, rhs: MIndex) -> Bool {
        return lhs.indices == rhs.indices
    }
    
    // e.g. (2, 1, 3) -> 2 + (1 * p) + (3 * p^2)
    public var hashValue: Int {
        let p = 31
        return indices.reversed().reduce(0) { (sum, next) -> Int in
            p &* sum &+ next
        }
    }
    
    // lex order
    public static func <(lhs: MIndex, rhs: MIndex) -> Bool {
        return lhs.indices.lexicographicallyPrecedes(rhs.indices)
    }
    
    public var description: String {
        return "(\( indices.map{ String($0) }.joined(separator: ", ")))"
    }
}

public struct MPolynomial<K: Field>: Ring, Module {
    public typealias CoeffRing = K
    
    // e.g. [(2, 1, 3) : 5] -> 5 * x^2 * y * z^3
    private let coeffs: [MIndex : K]
    
    public init(intValue n: Int) {
        self.init(K(intValue: n))
    }
    
    public init(_ a: K) {
        self.init([MIndex.zero : a])
    }
    
    public init(_ elements: ([Int], K) ...) {
        let coeffs = Dictionary(pairs: elements.map{ (i, a) in (MIndex(i), a) } )
        self.init(coeffs)
    }
    
    private init(_ coeffs: [MIndex : K]) {
        self.coeffs = coeffs.filter{ $0.value != .zero }
    }
    
    public static var zero: MPolynomial<K> {
        return MPolynomial([:])
    }
    
    internal var mIndices: [MIndex] {
        return coeffs.keys.sorted()
    }
    
    public var maxDegree: Int {
        return coeffs.keys.reduce(0) { max($0, $1.degree) }
    }
    
    public func coeff(_ indices: Int ...) -> K {
        return coeff(MIndex(indices))
    }
    
    public func coeff(_ i: MIndex) -> K {
        return coeffs[i] ?? .zero
    }
    
    public var leadCoeff: K {
        return mIndices.first.flatMap{ self.coeff($0) } ?? .zero
    }
    
    public var inverse: MPolynomial<K>? {
        return (maxDegree == 0) ? coeff(.zero).inverse.flatMap{ a in MPolynomial(a) } : nil
    }
    
    public func map(_ f: ((K) -> K)) -> MPolynomial<K> {
        return MPolynomial( coeffs.mapValues(f) )
    }
    
    public static func == (f: MPolynomial<K>, g: MPolynomial<K>) -> Bool {
        return (f.mIndices == g.mIndices) &&
            f.mIndices.forAll { i in f.coeff(i) == g.coeff(i) }
    }
    
    public static func + (f: MPolynomial<K>, g: MPolynomial<K>) -> MPolynomial<K> {
        var coeffs = f.coeffs
        for (i, a) in g.coeffs {
            coeffs[i] = coeffs[i, default: .zero] + a
        }
        return MPolynomial(coeffs)
    }
    
    public static prefix func - (f: MPolynomial<K>) -> MPolynomial<K> {
        return f.map { -$0 }
    }
    
    public static func * (f: MPolynomial<K>, g: MPolynomial<K>) -> MPolynomial<K> {
        var coeffs = [MIndex : K]()
        for (i, j) in f.mIndices.allCombinations(with: g.mIndices) {
            let k = i * j
            coeffs[k] = coeffs[k, default: .zero] + f.coeff(i) * g.coeff(j)
        }
        return MPolynomial(coeffs)
    }
    
    public static func * (r: K, f: MPolynomial<K>) -> MPolynomial<K> {
        return f.map { r * $0 }
    }
    
    public static func * (f: MPolynomial<K>, r: K) -> MPolynomial<K> {
        return f.map { $0 * r }
    }
    
    public var description: String {
        let (sub, sup) = (Letters.sub, Letters.sup)
        
        func toTerm(_ i: MIndex) -> String {
            return i.indices.enumerated().flatMap { (j, n) -> String? in
                if n > 0 {
                    return (n > 1) ? "x\(sub(j+1))\(sup(n))" : "x\(sub(j+1))"
                } else {
                    return nil
                }
            }.joined()
        }
        
        let res = mIndices.reversed().map { i -> String in
            let a = self.coeff(i)
            let x = toTerm(i)
            switch a {
            case  1: return x
            case -1: return "-\(x)"
            default: return "\(a)\(x)"
            }
        }.joined(separator: " + ")
        
        return res.isEmpty ? "0" : res
    }
    
    public static var symbol: String {
        return "\(K.symbol)[x₁ … ]"
    }
    
    public var hashValue: Int {
        return leadCoeff.hashValue
    }
}

