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
    public typealias Object = _Homology<chainType, A, R>.Summand
    public typealias Arrow  = _HomologyMap<chainType, A, A, R>
    
    public var sequence : ExactSequence<A, R>
    
    internal let H:    [_Homology<chainType, A, R>]       // [0,      1,      2]
    internal let map : [_HomologyMap<chainType, A, A, R>] // [0 -> 1, 1 -> 2, 2 -> 0]
    
    public let topDegree: Int
    public let bottomDegree: Int
    
    public init(_ chain0: _ChainComplex<chainType, A, R>, _ map0 : _ChainMap<chainType, A, A, R>,
                _ chain1: _ChainComplex<chainType, A, R>, _ map1 : _ChainMap<chainType, A, A, R>,
                _ chain2: _ChainComplex<chainType, A, R>, _ delta: _ChainMap<chainType, A, A, R>) {
        
        self.H    = [_Homology(chain0), _Homology(chain1), _Homology(chain2)]
        self.map  = [_HomologyMap(from: H[0], to: H[1], inducedFrom: map0),
                     _HomologyMap(from: H[1], to: H[2], inducedFrom: map1),
                     _HomologyMap(from: H[2], to: H[0], inducedFrom: delta)]
        
        self.topDegree    = Swift.max(chain0.topDegree, chain1.topDegree, chain2.topDegree)
        self.bottomDegree = Swift.min(chain0.offset,    chain1.offset,    chain2.offset)
        
        self.sequence  = ExactSequence(count: 3 * (topDegree - bottomDegree + 1))
        
        // fill arrows
        for i in 0 ..< sequence.length - 1 {
            sequence.arrows[i] = map[i % 3].chainMap.map
        }
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
        let k = seqIndex(i, n)
        return sequence[k].map{ Object(H[i], $0) } ?? nil
    }
    
    public subscript(k: Int) -> Object? {
        let i = gridIndex(k).0
        return sequence[k].map{ (s: SimpleModuleStructure<A, R>) in _Homology<chainType, A, R>.Summand(H[i], s) } ?? nil
    }
    
    internal var degrees: [Int] {
        return chainType.descending
            ? (bottomDegree ... topDegree).reversed().toArray()
            : (bottomDegree ... topDegree).toArray()
    }
    
    public mutating func fill(column i: Int, degree n: Int) {
        assert((0 ..< 3).contains(i))
        let k = seqIndex(i, n)
        sequence[k] = H[i][n].structure
    }
    
    public mutating func fill(column i: Int) {
        assert((0 ..< 3).contains(i))
        for n in bottomDegree ... topDegree {
            fill(column: i, degree: n)
        }
    }
    
    public mutating func solve(column i: Int, degree n: Int) -> Object? {
        sequence.solve(seqIndex(i, n))
        return self[i, n]
    }
    
    public mutating func solve(column i: Int) -> [Object?] {
        return (bottomDegree ... topDegree).map{ n in solve(column: i, degree: n) }
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
        return "\(H[0]) -> \(H[1]) -> \(H[2])"
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
