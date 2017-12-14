//
//  HomologyExactSequence.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/12.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias   HomologyExactSequence<A: FreeModuleBase, R: EuclideanRing> = _HomologyExactSequence<Descending, A, R>
public typealias CohomologyExactSequence<A: FreeModuleBase, R: EuclideanRing> = _HomologyExactSequence<Ascending , A, R>

public struct _HomologyExactSequence<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: Sequence, CustomStringConvertible {
    public typealias Object = ExactSequence<R>.Object
    
    internal let H:    [_Homology<chainType, A, R>]       // [0,      1,      2]
    internal let maps: [_HomologyMap<chainType, A, A, R>] // [0 -> 1, 1 -> 2, 2 -> 0]
    
    public let topDegree: Int
    public let bottomDegree: Int
    public var sequence : ExactSequence<R>

    public init(_ chain0: _ChainComplex<chainType, A, R>, _ map0 : _ChainMap<chainType, A, A, R>,
                _ chain1: _ChainComplex<chainType, A, R>, _ map1 : _ChainMap<chainType, A, A, R>,
                _ chain2: _ChainComplex<chainType, A, R>, _ delta: _ChainMap<chainType, A, A, R>) {
        
        self.H    = [_Homology(chain0), _Homology(chain1), _Homology(chain2)]
        self.maps  = [_HomologyMap(from: H[0], to: H[1], inducedFrom: map0),
                     _HomologyMap(from: H[1], to: H[2], inducedFrom: map1),
                     _HomologyMap(from: H[2], to: H[0], inducedFrom: delta)]
        
        self.topDegree    = Swift.max(chain0.topDegree, chain1.topDegree, chain2.topDegree)
        self.bottomDegree = Swift.min(chain0.offset,    chain1.offset,    chain2.offset)
        self.sequence  = ExactSequence(count: 3 * (topDegree - bottomDegree + 1))
    }
    
    public var length: Int {
        return (topDegree - bottomDegree + 1) * 3
    }
    
    internal func seqIndex(_ i: Int, _ n: Int) -> Int {
        return chainType.descending ? (topDegree - n) * 3 + i : (n - bottomDegree) * 3 + i
    }
    
    internal func gridIndex(_ k: Int) -> (Int, Int) {
        let (i, j) = (k >= 0) ? (k % 3, k / 3) : (k % 3 + 3, k / 3 - 1)
        return (i, chainType.descending ? topDegree - j : bottomDegree + j)
    }
    
    public subscript(i: Int, n: Int) -> Object? {
        assert((0 ..< 3).contains(i))
        return sequence[seqIndex(i, n)]
    }
    
    public subscript(k: Int) -> Object? {
        return sequence[k]
    }
    
    internal var degrees: [Int] {
        return chainType.descending
            ? (bottomDegree ... topDegree).reversed().toArray()
            : (bottomDegree ... topDegree).toArray()
    }
    
    private func arrow(_ k: Int) -> ExactSequence<R>.Arrow {
        let (i0, n0) = gridIndex(k)
        let (i1, n1) = gridIndex(k + 1)

        //    f
        // H0 --> H1
        
        let H0 = H[i0][n0]
        let H1 = H[i1][n1]
        let f = maps[i0]
        
        return ExactSequence<R>.Arrow{ i in
            let z = H0.generator(i)
            let w = f.appliedTo(z)
            let n = H1.summands.count
            return FreeModule(zip( 0 ..< n, H1.factorize(w.representative) ))
        }
    }
    
    public mutating func fill(column i1: Int, degree n1: Int) {
        assert((0 ..< 3).contains(i1))
        
        let k = seqIndex(i1, n1)
        sequence[k] = H[i1][n1].structure.asAbstract
        
        if sequence[k - 1] != nil && sequence.arrows[k - 1] == nil {
            sequence.arrows[k - 1] = arrow(k - 1)
        }
        
        if sequence[k + 1] != nil && sequence.arrows[k] == nil {
            sequence.arrows[k] = arrow(k)
        }
    }
    
    public mutating func fill(column i: Int) {
        assert((0 ..< 3).contains(i))
        for n in bottomDegree ... topDegree {
            fill(column: i, degree: n)
        }
    }
    
    @discardableResult
    public mutating func solve(column i: Int, degree n: Int, debug: Bool = false) -> Object? {
        sequence.solve(seqIndex(i, n), debug: debug)
        return self[i, n]
    }
    
    @discardableResult
    public mutating func solve(column i: Int, debug: Bool = false) -> [Object?] {
        return (bottomDegree ... topDegree).map{ n in solve(column: i, degree: n, debug: debug) }
    }
    
    public func assertExactness(column i: Int, degree n: Int, debug: Bool = false) {
        let k = seqIndex(i, n)
        sequence.assertExactness(at: k, debug: debug)
    }
    
    public func assertExactness(debug: Bool = false) {
        sequence.assertExactness(debug: debug)
    }
    
    public func makeIterator() -> AnyIterator<Object?> {
        let lazy = (0 ..< length).lazy.map{ k in self[k] }
        return AnyIterator(lazy.makeIterator())
    }
    
    public var description: String {
        return (0 ..< 3).map{"\(H[$0])"}.joined(separator: " -> ")
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
