//
//  Simplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct Vertex: Equatable, Comparable, Hashable, CustomStringConvertible {
    public let id: String
    internal let index: Int
    
    internal init(_ id: String, _ index: Int) {
        self.id = id
        self.index = index
    }
    
    public var hashValue: Int {
        return id.hashValue
    }
    
    public var description: String {
        return id
    }
    
    public static func ==(a: Vertex, b: Vertex) -> Bool {
        return a.id == b.id
    }
    
    public static func <(a: Vertex, b: Vertex) -> Bool {
        return a.index < b.index
    }
}

public struct VertexSet: CustomStringConvertible {
    public let vertices: [Vertex]
    public init(number: Int, prefix: String = "v") {
        self.vertices = (0 ..< number).map { Vertex("\(prefix)\($0)", $0) }
    }
    
    public func simplex(_ indices: Int...) -> Simplex {
        let vs = indices.map { vertices[$0] }
        return Simplex(vs)
    }
    
    public var description: String {
        return vertices.description
    }
}

// MEMO: 'un'ordered set of vertices (though we use OrderedSet)

public struct Simplex: FreeModuleBase, CustomStringConvertible {
    public let vertices: OrderedSet<Vertex>
    public var dim: Int {
        return vertices.count - 1
    }
    
    internal init<S: Sequence>(_ vertices: S) where S.Iterator.Element == Vertex {
        self.vertices = OrderedSet(sequence: vertices.sorted())
    }
    
    public func face(_ index: Int) -> Simplex {
        let vs = (0 ... dim).filter({$0 != index}).map{vertices[$0]}
        return Simplex(vs)
    }
    
    public func faces() -> [Simplex] {
        if dim == 0 {
            return []
        } else {
            return (0 ... dim).map{ face($0) }
        }
    }
    
    public func contains(_ s: Simplex) -> Bool {
        return s.vertices.isSubset(of: self.vertices)
    }
    
    public func allSubsimplices() -> [Simplex] {
        var queue = OrderedSet(sequence: [self])
        var i = 0
        while(i < queue.count) {
            let s = queue[i]
            if s.dim > 0 {
                queue += queue[i].faces()
            }
            i += 1
        }
        return Array(queue)
    }
    
    public func skeleton(_ dim: Int) -> [Simplex] {
        return allSubsimplices().filter{$0.dim <= dim}
    }
    
    public var hashValue: Int {
        return description.hashValue
    }
    
    public var description: String {
        return "(\(Array(vertices).map{$0.description}.joined(separator: ", ")))"
    }
    
    public static func ==(a: Simplex, b: Simplex) -> Bool {
        return Set(a.vertices) == Set(b.vertices)
    }
}

public struct SimplicialComplex {
    public let simplices: Set<Simplex>
    
    public init<S: Sequence>(_ simplices: S, generate: Bool = false) where S.Iterator.Element == Simplex {
        self.simplices = generate ?
            simplices.reduce(Set()) { $0.union($1.allSubsimplices()) }
            : Set(simplices)
    }
    
    public func chainComplex<R: Ring>() -> ChainComplex<Simplex, R> {
        typealias M = FreeModule<Simplex, R>
        typealias F = FreeModuleHom<Simplex, R>
        
        func sgn(_ i: Int) -> Int {
            return (i % 2 == 0) ? 1 : -1
        }
        
        let dim = simplices.reduce(0){ max($0, $1.dim) }
        
        var chns: [[Simplex]] = (0 ... dim).map{_ in []}
        for s in simplices {
            chns[s.dim].append(s)
        }
        
        var bmaps: [F] = []
        bmaps += (0 ... dim).map { (i) -> F in
            let from = chns[i]
            let map = Dictionary.generateBy(keys: from){ (s) -> M in
                return s.faces().enumerated().reduce(M.zero){ (res, el) -> M in
                    let (i, t) = el
                    return res + R(sgn(i)) * M(t)
                }
            }
            return F(inBasis: chns[i], outBasis: (i > 0) ? chns[i - 1] : [], mapping: map)
        }
        bmaps += [F.zero]
        
        return ChainComplex(chainBases: chns, boundaryMaps: bmaps)
    }
    
    public func homology<R: Ring>() -> Homology<Simplex, R> {
        return Homology(chainComplex())
    }
    
    public func ZHomology() -> Homology<Simplex, IntegerNumber> {
        return Homology(chainComplex())
    }
}
