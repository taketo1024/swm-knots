//
//  Simplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct Simplex: FreeModuleBase, CustomStringConvertible {
    public   let vertices: [Vertex] // ordered list of vertices.
    internal let vSet: Set<Vertex>  // unordered set of vertices.
    internal let id: String
    
    public init(_ V: VertexSet, _ indices: [Int]) {
        let vertices = indices.map{ V.vertex(at: $0) }
        self.init(vertices)
    }
    
    public init<S: Sequence>(_ vertices: S) where S.Iterator.Element == Vertex {
        self.vertices = vertices.sorted().unique()
        self.vSet = Set(self.vertices)
        self.id = "(\(self.vertices.map{$0.description}.joined(separator: ", ")))"
    }
    
    public var dim: Int {
        return vertices.count - 1
    }
    
    public func index(ofVertex v: Vertex) -> Int? {
        return vertices.index(of: v)
    }
    
    public func face(_ index: Int) -> Simplex {
        var vs = vertices
        vs.remove(at: index)
        return Simplex(vs)
    }
    
    public func faces() -> [Simplex] {
        if dim == 0 {
            return []
        } else {
            return (0 ... dim).map{ face($0) }
        }
    }
    
    public func contains(_ v: Vertex) -> Bool {
        return vSet.contains(v)
    }
    
    public func contains(_ s: Simplex) -> Bool {
        return s.vSet.isSubset(of: self.vSet)
    }
    
    public func allSubsimplices() -> [Simplex] {
        var queue = [self]
        var i = 0
        while(i < queue.count) {
            let s = queue[i]
            if s.dim > 0 {
                queue += queue[i].faces()
            }
            i += 1
        }
        return queue.unique()
    }
    
    public func join(_ s: Simplex) -> Simplex {
        return Simplex(self.vSet.union(s.vSet))
    }
    
    public func subtract(_ s: Simplex) -> Simplex {
        return Simplex(self.vSet.subtracting(s.vSet))
    }
    
    public func subtract(_ v: Vertex) -> Simplex {
        return Simplex(self.vSet.subtracting([v]))
    }
    
    public func boundary<R: Ring>() -> SimplicialChain<R> {
        let values = faces().enumerated().map { (i, t) -> (Simplex, R) in
            let value: R = (i % 2 == 0) ? 1 : -1
            return (t, value)
        }
        return SimplicialChain(Dictionary(pairs: values))
    }
    
    public var hashValue: Int {
        return id.hashValue
    }
    
    public var description: String {
        return id
    }
    
    public static func ==(a: Simplex, b: Simplex) -> Bool {
        return a.id == b.id // should be `a.verticesSet == b.verticesSet` but for performance.
    }
}

public extension Vertex {
    public func join(_ s: Simplex) -> Simplex {
        return Simplex([self] + s.vertices)
    }
    
    public func join<R: Ring>(_ chain: SimplicialChain<R>) -> SimplicialChain<R> {
        return SimplicialChain(chain.table.mapPairs { (s, r) -> (Simplex, R) in
            let t = self.join(s)
            let sgn = (t.vertices.index(of: self)! % 2 == 0) ? R.identity : -R.identity
            return (t, sgn * r)
        })
    }
}

public typealias SimplicialChain<R: Ring>     = FreeModule<Simplex, R>
public typealias DualSimplicialChain<R: Ring> = FreeModule<Dual<Simplex>, R>

public extension SimplicialChain where A == Simplex {
    public func boundary() -> SimplicialChain<R> {
        return self.reduce(SimplicialChain<R>.zero) { (res, next) -> SimplicialChain<R> in
            let (s, r) = next
            return res + r * s.boundary()
        }
    }
}

