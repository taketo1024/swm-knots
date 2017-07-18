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
