//
//  SimplicialMap.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/05.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyAlgebra

public struct SimplicialMap: GeometricComplexMap {
    public typealias ComplexType = SimplicialComplex
    public typealias Domain      = Simplex
    public typealias Codomain    = Simplex
    
    public var domain:   SimplicialComplex
    public var codomain: SimplicialComplex?
    private let map: (Vertex) -> Vertex
    
    public init(_ f: @escaping (Simplex) -> Simplex) {
        fatalError("TODO")
    }
    
    public init(from: SimplicialComplex, to: SimplicialComplex? = nil, _ map: @escaping (Vertex) -> Vertex) {
        self.domain = from
        self.codomain = to
        self.map = map
    }
    
    public init(from: SimplicialComplex, to: SimplicialComplex? = nil, _ map: [Vertex: Vertex]) {
        self.init(from: from, to: to, { v in map[v] ?? v })
    }
    
    public init(from: SimplicialComplex, to: SimplicialComplex? = nil, _ map: [(Vertex, Vertex)]) {
        self.init(from: from, to: to, Dictionary(pairs: map))
    }
    
    public var image: SimplicialComplex {
        let cells = domain.maximalCells.map { s in self.applied(to: s) }.unique()
        return SimplicialComplex(cells: cells, filterMaximalCells: true)
    }
    
    public func applied(to x: Vertex) -> Vertex {
        return map(x)
    }
    
    public func applied(to s: Simplex) -> Simplex {
        return Simplex(s.vertices.map{ self.applied(to: $0) }.unique())
    }
    
    public static func identity(from: SimplicialComplex) -> SimplicialMap {
        return SimplicialMap(from: from, to: from) { v in v }
    }
    
    public static func inclusion(from: SimplicialComplex, to: SimplicialComplex) -> SimplicialMap {
        return SimplicialMap(from: from, to: to) { v in v }
    }
    
    public static func diagonal(from: SimplicialComplex) -> SimplicialMap {
        return SimplicialMap(from: from) { v in v × v }
    }
    
    public static func projection(from: SimplicialComplex, _ i: Int) -> SimplicialMap {
        return SimplicialMap(from: from) { v in v.components[i] }
    }
}
