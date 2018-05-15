//
//  HomologyExactSequence.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/12/12.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyMath

public typealias   HomologyExactSequence<R: EuclideanRing> = _HomologyExactSequence<Descending, R>
public typealias CohomologyExactSequence<R: EuclideanRing> = _HomologyExactSequence< Ascending, R>

public struct _HomologyExactSequence<T: ChainType, R: EuclideanRing>: Sequence, CustomStringConvertible {
    public typealias H = _Homology<T, AbstractBasisElement, R>
    public typealias Map = _HomologyMap<T, AbstractBasisElement, AbstractBasisElement, R>
    public typealias Object = ExactSequence<R>.Object
    
    internal let h:    [H]   // [H0,  H1,  H2]
    internal let maps: [Map] // [   f0,  f1,  ∂]
    
    public let topDegree: Int
    public let bottomDegree: Int
    public var sequence : ExactSequence<R>

    // Induce from short ex. seq. of ChainComplexes.
    public init<A, B, C>(_ chain0: _ChainComplex<T, A, R>, _ map0 : _ChainMap<T, A, B, R>,
                         _ chain1: _ChainComplex<T, B, R>, _ map1 : _ChainMap<T, B, C, R>,
                         _ chain2: _ChainComplex<T, C, R>, _ delta: _ChainMap<T, C, A, R>) {
        
        let (h0, h1, h2) = (H(chainComplex: chain0.asAbstract()),
                            H(chainComplex: chain1.asAbstract()),
                            H(chainComplex: chain2.asAbstract()))
        
        let (f0, f1,  d) = (Map.induced(from:  map0.asAbstract(from: chain0, to: chain1), codomainStructure: h1),
                            Map.induced(from:  map1.asAbstract(from: chain1, to: chain2), codomainStructure: h2),
                            Map.induced(from: delta.asAbstract(from: chain2, to: chain0), codomainStructure: h0))
       
        self.init(h0, f0, h1, f1, h2, d)
    }
    
    public init(_ h0: H, _ map0 : Map, _ h1: H, _ map1 : Map, _ h2: H, _ delta: Map) {
        self.h = [h0, h1, h2]
        self.maps = [map0, map1, delta]
        
        self.topDegree    = Swift.max(h0.topDegree, h1.topDegree, h2.topDegree)
        self.bottomDegree = Swift.min(h0.offset,    h1.offset,    h2.offset)
        self.sequence  = ExactSequence(count: 3 * (topDegree - bottomDegree + 1))
    }
    
    public subscript(i: Int) -> [Object?] {
        assert((0 ..< 3).contains(i))
        return (bottomDegree ... topDegree).map { n in self[i, n] }
    }
    
    public subscript(i: Int, n: Int) -> Object? {
        assert((0 ..< 3).contains(i))
        return sequence[seqIndex(i, n)]
    }
    
    public var length: Int {
        return (topDegree - bottomDegree + 1) * 3
    }
    
    internal func seqIndex(_ i: Int, _ n: Int) -> Int {
        return T.descending ? (topDegree - n) * 3 + i : (n - bottomDegree) * 3 + i
    }
    
    internal func gridIndex(_ k: Int) -> (Int, Int) {
        let (i, j) = (k >= 0) ? (k % 3, k / 3) : (k % 3 + 3, k / 3 - 1)
        return (i, T.descending ? topDegree - j : bottomDegree + j)
    }
    
    internal var degrees: [Int] {
        return T.descending
            ? (bottomDegree ... topDegree).reversed().toArray()
            : (bottomDegree ... topDegree).toArray()
    }
    
    public mutating func isZeroMap(_ i: Int) -> Bool {
        return sequence.isZeroMap(i)
    }
    
    public mutating func isInjective(_ i: Int) -> Bool {
        return sequence.isZeroMap(i - 1)
    }
    
    public mutating func isSurjective(_ i: Int) -> Bool {
        return sequence.isZeroMap(i + 1)
    }
    
    public mutating func isIsomorphic(_ i: Int) -> Bool {
        return sequence.isIsomorphic(i)
    }

    public mutating func fill(column i: Int, degree n: Int) {
        assert((0 ..< 3).contains(i))

        let k = seqIndex(i, n)
        
        sequence[k] = h[i][n]

        if sequence[k - 1] != nil && sequence.arrows[k - 1].map == nil {
            sequence.arrows[k - 1].map = makeMap(k - 1)
        }

        if sequence[k + 1] != nil && sequence.arrows[k].map == nil {
            sequence.arrows[k].map = makeMap(k)
        }
    }
    
    public mutating func fill(columns: Int ...) {
        assert(columns.forAll{ i in (0 ..< 3).contains(i) })
        for i in columns {
            for n in bottomDegree ... topDegree {
                fill(column: i, degree: n)
            }
        }
    }
    
    private func makeMap(_ k: Int) -> ExactSequence<R>.Map {
        let (i, _) = gridIndex(k)
        let (h0, f) = (h[i], maps[i])
        
        return ExactSequence<R>.Map { (z: FreeModule<AbstractBasisElement, R>) in
            let x = h0.homologyClass(of: z)
            let y = f.applied(to: x)
            return y.representative
        }
    }
    
    @discardableResult
    public mutating func solve(column i: Int, degree n: Int) -> Object? {
        sequence.solve(seqIndex(i, n))
        return self[i, n]
    }
    
    @discardableResult
    public mutating func solve(column i: Int) -> [Object?] {
        return (bottomDegree ... topDegree).map { n in
            self.solve(column: i, degree: n)
        }
    }
    
    @discardableResult
    public mutating func solve() -> [Object?] {
        return sequence.solve()
    }
    
    public func assertExactness(column i: Int, degree n: Int) {
        let k = seqIndex(i, n)
        sequence.assertExactness(at: k)
    }
    
    public func assertExactness() {
        sequence.assertExactness()
    }
    
    public func makeIterator() -> AnyIterator<Object?> {
        let lazy = (0 ..< length).lazy.map{ k in self.sequence[k] }
        return AnyIterator(lazy.makeIterator())
    }
    
    public var description: String {
        return h.map{ $0.description }.joined(separator: " -> ")
    }
    
    public var detailDescription: String {
        func s(_ i: Int, _ n: Int) -> String {
            return self[i, n].map{ "\($0)" } ?? "?"
        }
        return "\(self.description)\n--------------------\n"
            + degrees.map { n -> String in
                "\(n): \t" + (0 ..< 3).map{ i in self[i, n].map{ "\($0)" } ?? "?" }.joined(separator: "\t-> ")
                }.joined(separator: "\t->\n")
            + "\t-> 0"
    }
}
