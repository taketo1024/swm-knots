//
//  VertexSet.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/18.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public final class VertexSet: CustomStringConvertible {
    public private(set) var vertices: [Vertex]
    private var bcenter2simplex: [Vertex : Simplex] = [:]
    private var simplex2bcenter: [Simplex: Vertex ] = [:]
    
    public init() {
        self.vertices = []
    }
    
    public init(number: Int, prefix: String = "v") {
        self.vertices = [] // MEMO must initialize before passing `self` as argument...
        self.vertices = (0 ..< number).map { Vertex($0, "\(prefix)\($0)", self) }
    }
    
    public func add(label: String? = nil, barycenterOf s: Simplex? = nil) -> Vertex {
        let index = vertices.count
        let v = Vertex(index, label ?? "v\(index)", self)
        vertices.append(v)
        
        if let s = s {
            bcenter2simplex[v] = s
            simplex2bcenter[s] = v
        }
        
        return v
    }
    
    public func vertex(at i: Int) -> Vertex {
        return vertices[i]
    }
    
    public func barycenterOf(_ s: Simplex) -> Vertex? {
        return simplex2bcenter[s]
    }
    
    public func simplex(forBarycenter v: Vertex) -> Simplex? {
        return bcenter2simplex[v]
    }
    
    public var description: String {
        return vertices.description
    }
}
