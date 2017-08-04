//
//  VertexSet.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/18.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct VertexSet: CustomStringConvertible {
    public private(set) var vertices: [Vertex]
    
    public init() {
        self.vertices = []
    }
    
    public init(count n: Int, prefix: String = "v") {
        self.vertices = [] // MEMO must initialize before passing `self` as argument...
        self.vertices = (0 ..< n).map { Vertex($0, "\(prefix)\($0)", self) }
    }
    
    public subscript(i: Int) -> Vertex {
        return vertices[i]
    }
    
    public func vertex(at i: Int) -> Vertex {
        return vertices[i]
    }
    
    public mutating func add(label: String? = nil) -> Vertex {
        let index = vertices.count
        let v = Vertex(index, label ?? "v\(index)", self)
        vertices.append(v)
        return v
    }
    
    public var description: String {
        return vertices.description
    }
}
