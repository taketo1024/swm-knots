//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/09/17.
//

import SwiftGraph

public struct SeifertGraph {
    private let graph: WeightedGraph<Int, Int>
    
    public init(_ L: Link) {
        let s = L.orientationPreservingState
        let L0 = L.resolved(by: s)
        let comps = L0.components
        let graph = WeightedGraph<Int, Int>(vertices: Array(comps.indices))
        
        func vertex(containing edge: Link.Edge) -> Int {
            graph.vertices.first { comps[$0].edges.contains(edge) }!
        }
        
        for x in L0.crossings {
            let (i, j) = (x.mode == .V) ? (0, 1) : (0, 2)
            let (e1, e2) = (x.edges[i], x.edges[j])
            let v1 = vertex(containing: e1)
            let v2 = vertex(containing: e2)
            graph.addEdge(from: v1, to: v2, weight: x.id)
        }
        
        self.graph = graph
    }
    
    public var spanningTree: [Int] {
        graph.mst()!.map{ $0.weight }
    }
}
