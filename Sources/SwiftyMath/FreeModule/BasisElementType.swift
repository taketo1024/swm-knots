//
//  BasisElementType.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/12/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol BasisElementType: SetType, Comparable {
    var degree: Int { get }
    var dual: Dual<Self> { get }
}

public extension BasisElementType {
    public var degree: Int { return 1 }
    
    public var dual: Dual<Self> {
        return Dual(self)
    }
}

// Derived Bases
public struct Dual<A: BasisElementType>: BasisElementType {
    public let base: A
    public init(_ a: A) {
        base = a
    }
    
    public var degree: Int {
        return base.degree
    }
    
    public var hashValue: Int {
        return base.hashValue
    }
    
    public func pair(_ s: A) -> Int {
        return (base == s) ? 1 : 0
    }
    
    public static func ==(a: Dual<A>, b: Dual<A>) -> Bool {
        return a.base == b.base
    }
    
    public static func < (a1: Dual<A>, a2: Dual<A>) -> Bool {
        return a1.base < a2.base
    }
    
    public var description: String {
        return "\(base)*"
    }
}

public struct Tensor<A: BasisElementType>: BasisElementType {
    public let factors: [A]
    public init(_ factors: [A]) {
        self.factors = factors
    }
    
    public init(_ factors: A ...) {
        self.init(factors)
    }
    
    public subscript(i: Int) -> A {
        return factors[i]
    }
    
    public var degree: Int {
        return factors.sum { $0.degree }
    }
    
    public typealias   Product<R: Ring> = (A, A) -> [(A, R)]
    public typealias Coproduct<R: Ring> = (A) -> [(A, A, R)]
    
    public func applied<R: Ring>(_ m: Product<R>, at: (Int, Int), to j: Int) -> FreeModule<Tensor<A>, R> {
        let (i1, i2) = at
        let (e1, e2) = (self[i1], self[i2])
        
        return m(e1, e2).sum { (e, a) in
            var factors = self.factors
            factors.remove(at: i2)
            factors.remove(at: i1)
            factors.insert(e, at: j)
            return FreeModule(Tensor(factors), a)
        }
    }
    
    public func applied<R: Ring>(_ c: Coproduct<R>, at i: Int, to: (Int, Int)) -> FreeModule<Tensor<A>, R> {
        let (j1, j2) = to
        let e = self[i]
        
        return c(e).sum { (e1, e2, a)  in
            var factors = self.factors
            factors.remove(at: i)
            factors.insert(e1, at: j1)
            factors.insert(e2, at: j2)
            return FreeModule(Tensor(factors), a)
        }
    }
    
    public func mapFactors<R>(_ f: (A) -> [(A, R)]) -> FreeModule<Tensor<A>, R> {
        let all = factors.reduce([([], .identity)]) { (res, e) -> [([A], R)] in
            f(e).flatMap{ (e, r) in
                res.map{ (factors, r0) in (factors + [e], r0 * r) }
            }
        }
        return all.sum{ (factors, r) in
            return FreeModule(Tensor(factors), r)
        }
    }
    
    public static func ⊗(t1: Tensor<A>, t2: Tensor<A>) -> Tensor<A> {
        return Tensor(t1.factors + t2.factors)
    }
    
    public static func < (t1: Tensor<A>, t2: Tensor<A>) -> Bool {
        return t1.factors.lexicographicallyPrecedes(t2.factors)
    }
    
    public static func generateBasis(from basis: [A], pow n: Int) -> [Tensor<A>] {
        return (0 ..< n).reduce([[]]) { (res, _) -> [[A]] in
            res.flatMap{ (factors: [A]) -> [[A]] in
                basis.map{ x in factors + [x] }
            }
            }.map{ factors in Tensor(factors) }
    }
    
    public var description: String {
        return factors.map{ $0.description }.joined(separator: "⊗")
    }
    
    public var hashValue: Int {
        let p = 31
        return factors.reduce(0){ (res, f) in res &* p &+ f.hashValue }
    }
}

extension Tensor: Codable where A: Codable {
    public init(from decoder: Decoder) throws {
        fatalError()
    }
    
    public func encode(to encoder: Encoder) throws {
        fatalError()
    }
}
