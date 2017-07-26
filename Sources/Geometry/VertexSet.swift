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
    
    public init() {
        self.vertices = []
    }
    
    public init(number: Int, prefix: String = "v") {
        self.vertices = [] // MEMO must initialize before passing `self` as argument...
        self.vertices = (0 ..< number).map { Vertex($0, "\(prefix)\($0)", self) }
    }
    
    public func add(label: String? = nil) -> Vertex {
        let index = vertices.count
        let v = Vertex(index, label ?? "v\(index)", self)
        vertices.append(v)
        return v
    }
    
    public func vertex(at i: Int) -> Vertex {
        return vertices[i]
    }
    
    public var description: String {
        return vertices.description
    }
}
