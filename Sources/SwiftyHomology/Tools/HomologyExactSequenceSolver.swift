//
//  HomologyExactSequence.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/12/12.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyMath

public struct HomologyExactSequenceSolver<A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing>: CustomStringConvertible {
    public typealias Object = ExactSequenceSolver<R>.Object
    
    public let C0: ChainComplex<A, R>
    public let C1: ChainComplex<B, R>
    public let C2: ChainComplex<C, R>
    
    internal let map0:  ChainMap<A, B, R>
    internal let map1:  ChainMap<B, C, R>
    internal let delta: ChainMap<C, A, R>
    
    public let topDegree: Int
    public let bottomDegree: Int
    public var sequence : ExactSequenceSolver<R>
    
    public init(_ C0: ChainComplex<A, R>, _ f0: ChainMap<A, B, R>,
                _ C1: ChainComplex<B, R>, _ f1: ChainMap<B, C, R>,
                _ C2: ChainComplex<C, R>, _  d: ChainMap<C, A, R>) {
        
        assert(f0.degree == 0)
        assert(f1.degree == 0)
        assert(d.degree == 1 || d.degree == -1)

        self.C0 = C0
        self.C1 = C1
        self.C2 = C2

        self.map0  = f0
        self.map1  = f1
        self.delta = d
        
        self.topDegree    = [C0.topDegree,    C1.topDegree,    C2.topDegree   ].max()!
        self.bottomDegree = [C0.bottomDegree, C1.bottomDegree, C2.bottomDegree].min()!
        self.sequence  = ExactSequenceSolver(count: 3 * (topDegree - bottomDegree + 1))
    }
    
    public var length: Int {
        return (topDegree - bottomDegree + 1) * 3
    }
    
    public var descending: Bool {
        return delta.degree == -1
    }
    
    internal func seqIndex(_ n: Int, _ i: Int) -> Int {
        return descending ? (topDegree - n) * 3 + i : (n - bottomDegree) * 3 + i
    }
    
    internal func gridIndex(_ k: Int) -> (Int, Int) {
        let (i, j) = (k >= 0) ? (k % 3, k / 3) : (k % 3 + 3, k / 3 - 1)
        return (descending ? topDegree - j : bottomDegree + j, i)
    }
    
    public subscript(n: Int, i: Int) -> Object? {
        assert((0 ..< 3).contains(i))
        return sequence[seqIndex(n, i)]
    }
    
    internal var degrees: [Int] {
        return descending
            ? (bottomDegree ... topDegree).reversed().toArray()
            : (bottomDegree ... topDegree).toArray()
    }
    
    public func column(_ i: Int) -> ModuleSequence<AbstractBasisElement, R> {
        return ModuleSequence(list: degrees.map{ n in (n, self[n, i]) })
    }
    
    public mutating func fill(_ n: Int, _ i: Int) {
        assert((0 ..< 3).contains(i))
        
        let k = seqIndex(n, i)
        
        sequence[k] = {
            switch i {
            case 0: return C0.homology(n)?.asAbstract()
            case 1: return C1.homology(n)?.asAbstract()
            case 2: return C2.homology(n)?.asAbstract()
            default: fatalError()
            }
        }()
        
        if sequence[k - 1] != nil && sequence.arrows[k - 1].matrix == nil {
            sequence.arrows[k - 1].matrix = makeMatrix(k - 1)
        }
        
        if sequence[k + 1] != nil && sequence.arrows[k].matrix == nil {
            sequence.arrows[k].matrix = makeMatrix(k)
        }
    }
    
    private func makeMatrix(_ k: Int) -> Matrix<R>? {
        let (n0, i0) = gridIndex(k)
        let (n1,  _) = gridIndex(k + 1)
        
        switch i0 {
        case 0: return makeMatrix(C0.homology(n0), map0[n0],  C1.homology(n1))
        case 1: return makeMatrix(C1.homology(n0), map1[n0],  C2.homology(n1))
        case 2: return makeMatrix(C2.homology(n0), delta[n0], C0.homology(n1))
        default: fatalError()
        }
    }
    
    private func makeMatrix<X, Y>(_ s0: SimpleModuleStructure<X, R>?, _ f: @escaping (FreeModule<X, R>) -> FreeModule<Y, R>, _ s1: SimpleModuleStructure<Y, R>?) -> Matrix<R>? {
        guard let s0 = s0, let s1 = s1 else {
            return nil
        }
        
        let grid = s0.generators.flatMap { x in s1.factorize(f(x)) }
        return Matrix(rows: s0.generators.count, cols: s1.generators.count, grid: grid).transposed
    }
    
    public mutating func fill(columns: Int ...) {
        for i in columns {
            for n in bottomDegree ... topDegree {
                fill(n, i)
            }
        }
    }
    
    @discardableResult
    public mutating func solve(_ n: Int, _ i: Int) -> Object? {
        sequence.solve(seqIndex(n, i))
        return self[n, i]
    }
    
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
    
    public func describeMap(_ n: Int, _ i: Int) {
        return sequence.describeMap(seqIndex(n, i))
    }
    
    public func assertExactness(_ n: Int, _ i: Int, debug: Bool = false) {
        let k = seqIndex(n, i)
        sequence.assertExactness(at: k, debug: debug)
    }
    
    public func assertExactness(debug: Bool = false) {
        sequence.assertExactness(debug: debug)
    }
    
    public func makeIterator() -> AnyIterator<Object?> {
        let lazy = (0 ..< length).lazy.map{ k in self.sequence[k] }
        return AnyIterator(lazy.makeIterator())
    }
    
    public var description: String {
        let title = [C0.name, C1.name, C2.name].map{ s in "H(\(s))" }.joined(separator: " -> ")
        let head = "n\\i\t" + (0 ... 2).map{ i in "\(i)" }.joined(separator: "\t\t")
        let lines = degrees.map { n -> String in
            "\(n)\t" + (0 ..< 3).map { i in
                let k = self.seqIndex(n, i)
                return "\(sequence.objectDescription(k))\t\(sequence.arrowDescription(k))\t"
            }.joined()
        }
        return ([title, head] + lines).joined(separator: "\n")
    }
}
