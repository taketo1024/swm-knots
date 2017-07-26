//
//  Vertex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/27.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct Vertex: SetType, Comparable {
    public let index: Int
    public let label: String
    public let vertexSet: VertexSet
    
    // TODO should have reference to VertexSet?
    
    internal init(_ index: Int, _ label: String, _ vertexSet: VertexSet) {
        self.index = index
        self.label = label
        self.vertexSet = vertexSet
    }
    
    public var hashValue: Int {
        return index
    }
    
    public var description: String {
        return label
    }
    
    public static func ==(a: Vertex, b: Vertex) -> Bool {
        return (a.vertexSet === b.vertexSet) && (a.index == b.index)
    }
    
    public static func <(a: Vertex, b: Vertex) -> Bool {
        return a.index < b.index
    }
}
