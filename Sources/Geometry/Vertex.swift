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
    
    // TODO should have reference to VertexSet?
    
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
    private var bcenter2simplex: [Vertex : Simplex] = [:]
    private var simplex2bcenter: [Simplex: Vertex ] = [:]
    
    public init() {
        self.vertices = []
    }
    
    public init(number: Int, prefix: String = "v") {
        self.vertices = (0 ..< number).map { Vertex($0, "\(prefix)\($0)") }
    }
    
    mutating func add(label: String? = nil, barycenterOf s: Simplex? = nil) -> Vertex {
        let index = vertices.count
        let v = Vertex(index, label ?? "v\(index)")
        vertices.append(v)
        
        if let s = s {
            bcenter2simplex[v] = s
            simplex2bcenter[s] = v
        }
        
        return v
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
    
    // TODO: remove
    public func simplex(_ indices: Int...) -> Simplex {
        return simplex(indices: indices)
    }
    
    // TODO: remove
    public func simplex(indices: [Int]) -> Simplex {
        let vs = indices.map { vertices[$0] }
        return Simplex(vs)
    }
}

