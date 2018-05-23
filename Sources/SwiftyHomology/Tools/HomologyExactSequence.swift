//
//  HomologyExactSequence.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/12/12.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyMath

/*
public typealias   HomologyExactSequence<R: EuclideanRing> = _HomologyExactSequence<Descending, R>
public typealias CohomologyExactSequence<R: EuclideanRing> = _HomologyExactSequence< Ascending, R>

public struct _HomologyExactSequence<T: ChainType, R: EuclideanRing>: Sequence, CustomStringConvertible {
    public typealias H = _Homology<T, AbstractBasisElement, R>
    public typealias Map = _HomologyMap<T, AbstractBasisElement, AbstractBasisElement, R>
    public typealias Object = ExactSequence<R>.Object
    
    internal let h:    [H]   // [H0,  H1,  H2]
    internal let maps: [Map] // [   f0,  f1,  ∂]
    
    public var sequence : ExactSequence<R>

    public init<A, B, C>(_ chain0: _ChainComplex<T, A, R>, _ map0 : _ChainMap<T, A, B, R>,
                         _ chain1: _ChainComplex<T, B, R>, _ map1 : _ChainMap<T, B, C, R>,
                         _ chain2: _ChainComplex<T, C, R>, _ delta: _ChainMap<T, C, A, R>) {
        
        let SES = _ChainComplexSES(chain0, map0, chain1, map1, chain2, delta)
        
        self.init(SES)
    }
    
    public init<A, B, C>(_ S: _ChainComplexSES<T, A, B, C, R>) {
        let (c0, c1, c2) = (S.c0, S.c1, S.c2)
        let (f0, f1, f2)  = (S.f0, S.f1, S.d)
        
        let (h0, h1, h2) = (H(chainComplex: c0.asAbstract()),
                            H(chainComplex: c1.asAbstract()),
                            H(chainComplex: c2.asAbstract()))
        
        let (g0, g1, g2) = (Map.induced(from: f0.asAbstract(from: c0, to: c1), codomainStructure: h1),
                            Map.induced(from: f1.asAbstract(from: c1, to: c2), codomainStructure: h2),
                            Map.induced(from: f2.asAbstract(from: c2, to: c0), codomainStructure: h0))
        
        self.init(h0, g0, h1, g1, h2, g2)

    }
    
    public init(_ h0: H, _ map0 : Map, _ h1: H, _ map1 : Map, _ h2: H, _ delta: Map) {
        self.h = [h0, h1, h2]
        self.maps = [map0, map1, delta]
        
        let (n0, n1) = (h.map{ $0.offset }.min()!, h.map{ $0.topDegree }.max()!)
        self.sequence  = ExactSequence(count: 3 * (n1 - n0 + 1))
    }
    
    public subscript(n: Int, i: Int) -> Object? {
        return sequence[seqIndex(n, i)]
    }
    
    public var topDegree: Int {
        return h.map{ $0.topDegree }.max()!
    }
    
    public var bottomDegree: Int {
        return h.map{ $0.offset }.min()!
    }
    
    public var length: Int {
        return (topDegree - bottomDegree + 1) * 3
    }
    
    internal func seqIndex(_ n: Int, _ i: Int) -> Int {
        assert((0 ..< 3).contains(i))
        return T.descending ? (topDegree - n) * 3 + i : (n - bottomDegree) * 3 + i
    }
    
    internal func gridIndex(_ k: Int) -> (Int, Int) {
        let (i, j) = (k >= 0) ? (k % 3, k / 3) : (k % 3 + 3, k / 3 - 1)
        return (T.descending ? topDegree - j : bottomDegree + j, i)
    }
    
    internal var degrees: [Int] {
        return T.descending
            ? (bottomDegree ... topDegree).reversed().toArray()
            : (bottomDegree ... topDegree).toArray()
    }
    
    public func isZeroMap(_ n: Int, _ i: Int) -> Bool {
        return sequence.isZeroMap(seqIndex(n, i))
    }
    
    public func isInjective(_ n: Int, _ i: Int) -> Bool {
        return sequence.isInjective(seqIndex(n, i))
    }
    
    public func isSurjective(_ n: Int, _ i: Int) -> Bool {
        return sequence.isSurjective(seqIndex(n, i))
    }
    
    public func isIsomorphic(_ n: Int, _ i: Int) -> Bool {
        return sequence.isIsomorphic(seqIndex(n, i))
    }

    public mutating func fill(_ n: Int, _ i: Int) {
        assert((0 ..< 3).contains(i))

        let k = seqIndex(n, i)
        
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
                fill(n, i)
            }
        }
    }
    
    private func makeMap(_ k: Int) -> ExactSequence<R>.Map {
        let (_, i) = gridIndex(k)
        let (h0, f) = (h[i], maps[i])
        
        return ExactSequence<R>.Map { (z: FreeModule<AbstractBasisElement, R>) in
            let x = h0.homologyClass(of: z)
            let y = f.applied(to: x)
            return y.representative
        }
    }
    
    @discardableResult
    public mutating func solve(_ n: Int, _ i: Int) -> Object? {
        sequence.solve(seqIndex(n, i))
        return self[n, i]
    }
    
    @discardableResult
    public mutating func solve(column i: Int) -> [Object?] {
        return (bottomDegree ... topDegree).map { n in
            self.solve(n, i)
        }
    }
    
    public mutating func solve() {
        return sequence.solve()
    }
    
    public func describe(_ n: Int, _ i: Int) {
        return sequence.describe(seqIndex(n, i))
    }
    
    public func assertExactness(_ n: Int, _ i: Int) {
        let k = seqIndex(n, i)
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
        let title = h.map{ h in h.description }.joined(separator: " -> ")
        let head = "n\\i\t" + h.enumerated().map{ (i, _) in "\(i)" }.joined(separator: "\t\t")
        let lines = degrees.map { n -> String in
            "\(n)\t" + (0 ..< 3).map { i in
                let k = self.seqIndex(n, i)
                return "\(sequence.objectDescription(k))\t\(sequence.arrowDescription(k))\t"
                }.joined()
        }
        return ([title, head] + lines).joined(separator: "\n")
    }
}
*/
