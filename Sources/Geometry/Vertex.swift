//
//  Vertex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/27.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct Vertex: Equatable, Comparable, Hashable, CustomStringConvertible {
    public let index: Int
    public let label: String
    
    internal init(_ index: Int, _ label: String) {
        self.index = index
        self.label = label
    }
    
    public var hashValue: Int {
        return index
    }
    
    public var description: String {
        return label
    }
    
    public static func ==(a: Vertex, b: Vertex) -> Bool {
        return a.index == b.index
    }
    
    public static func <(a: Vertex, b: Vertex) -> Bool {
        return a.index < b.index
    }
}

public struct VertexSet: CustomStringConvertible {
    public private(set) var vertices: [Vertex]
    
    public init(number: Int, prefix: String = "v") {
        self.vertices = (0 ..< number).map { Vertex($0, "\(prefix)\($0)") }
    }
    
    public func simplex(_ indices: Int...) -> Simplex {
        return simplex(indices: indices)
    }
    
    public func simplex(indices: [Int]) -> Simplex {
        let vs = indices.map { vertices[$0] }
        return Simplex(vs)
    }
    
    mutating func add(label: String? = nil) -> Vertex {
        let index = vertices.count
        let v = Vertex(index, label ?? "v\(index)")
        vertices.append(v)
        return v
    }
    
    public var description: String {
        return vertices.description
    }
}

