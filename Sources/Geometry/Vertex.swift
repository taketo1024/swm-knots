//
//  Vertex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/27.
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
        return simplex(indices: indices)
    }
    
    public func simplex(indices: [Int]) -> Simplex {
        let vs = indices.map { vertices[$0] }
        return Simplex(vs)
    }
    
    public var description: String {
        return vertices.description
    }
}

