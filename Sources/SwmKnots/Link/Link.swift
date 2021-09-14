//
//  Link.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

//
//  Link.swift
//  SwiftyTopology
//
//  Created by Taketo Sano on 2018/03/28.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import SwmCore

public struct Link: Equatable, CustomStringConvertible {
    public typealias State = BitSequence

    public let name: String
    public let crossings: [Crossing]
    
    internal init(name: String, crossings: [Crossing]) {
        self.name = name
        self.crossings = crossings
    }
    
    public static var empty: Link {
        Link(name: "∅", crossings: [])
    }
    
    public static var unknot: Link {
        var L = Link(name: "○", pdCode: [1, 2, 2, 1])
        L.resolve(0, 0)
        return L
    }
    
    public func copy(name: String? = nil, diffX: Int = 0, diffE: Int = 0) -> Link {
        let myEdges = Dictionary(edges.map{ e in (e.id, e) })
        let cpEdges = myEdges.mapPairs{ (id, _) in (id, Edge(id + diffE)) }
        let cpCross = Dictionary(crossings.map { x -> (Int, Crossing) in
            let e = x.edges.map{ e in cpEdges[e.id]! }
            let cpX = Crossing(id: x.id + diffX, edges: (e[0], e[1], e[2], e[3]), mode: x.mode)
            return (x.id, cpX)
        })
        
        for (id, e) in cpEdges {
            let e0 = myEdges[id]!
            let (p0, p1) = (e0.endPoint0, e0.endPoint1)
            e.endPoint0 = (cpCross[ p0.crossing.id ]!, p0.index)
            e.endPoint1 = (cpCross[ p1.crossing.id ]!, p1.index)
        }
        
        let result = cpCross.sorted{ $0.key }.map{ $0.value }
        return Link(name: name ?? self.name, crossings: result)
    }
    
    public var crossingNumber: Int {
        crossings.count { x in !x.isResolved }
    }
    
    public var crossingNumber⁺: Int {
        crossings.count { x in x.crossingSign == 1 }
    }
    
    public var crossingNumber⁻: Int {
        crossings.count { x in x.crossingSign == -1 }
    }
    
    public var writhe: Int {
        crossings.sum { x in x.crossingSign }
    }
    
    public var reversed: Link {
        let L = self.copy(name: "\(name)r")
        for e in L.edges {
            e.reverse()
        }
        return L
    }
    
    public var mirrored: Link {
        let L = self.copy(name: "\(name)m")
        for x in L.crossings {
            x.changeCrossing()
        }
        return L
    }
    
    public func crossingChanged(at i: Int) -> Link {
        let L = self.copy(name: "\(name)'")
        L.crossings[i].changeCrossing()
        return L
    }
    
    public var edges: [Edge] {
        crossings.flatMap{ x in x.edges }.uniqued().sorted()
    }
    
    public var components: [Component] {
        var queue = edges
        var comps: [Component] = []
        
        while !queue.isEmpty {
            var comp: [Edge] = []
            
            let first = queue.first!
            var e = first
            
            while queue.contains(e) {
                queue.findAndRemove(element: e)
                comp.append(e)
                e = e.nextEdge
            }
            
            assert(e == first)
            
            comps.append(Component(comp))
        }
        
        return comps
    }
    
    /*
     *     \ /     0     \ /
     *      /     ===>   | |
     *     / \           / \
     *
     *
     *     \ /     1     \_/
     *      /     ===>
     *     / \           /‾\
     */
    
    public mutating func resolve(_ i: Int, _ s: Bit) {
        crossings[i].resolve(s)
        reorientEdges()
    }
    
    public func resolved(_ i: Int, _ s: Bit) -> Link {
        var L = self.copy(name: "\(name)\(Format.sub(s.description))")
        L.resolve(i, s)
        return L
    }
    
    public func resolved(by state: State) -> Link {
        let L = self.copy()
        let xs = L.crossings.filter{ !$0.isResolved }
        
        assert(xs.count == state.length)
        
        for (x, s) in zip(xs, state) {
            x.resolve(s)
        }
        L.reorientEdges()
        
        return L
    }
    
    public func resolvedPair(at i: Int) -> (Link, Link) {
        (resolved(i, 0), resolved(i, 1))
    }
    
    private func reorientEdges() {
        var queue = edges
        while !queue.isEmpty {
            let first = queue.first!
            var e = first
            
            while queue.contains(e) {
                queue.findAndRemove(element: e)
                
                let next = e.nextEdge
                
                let (x, i) = e.endPoint1
                let j = x.adjacentEdge(i).index
                
                if next.endPoint0 != (x, j) {
                    next.reverse()
                    assert(next.endPoint0 == (x, j))
                }
                e = next
            }
            
            assert(e == first)
        }
    }
    
    public var orientationPreservingState: State {
        State( crossings.compactMap{ x -> Bit? in
            x.isResolved
                ? nil
                : x.crossingSign == 1 ? 0 : 1
        } )
    }
    
    public var seifertCircles: [Component] {
        resolved(by: orientationPreservingState).components
    }
    
    public var numberOfSeifertCircles: Int {
        seifertCircles.count
    }
    
    public var seifertGraph: Graph<Int, Component, Int> {
        typealias SeifertGraph = Graph<Int, Component, Int>
        var G = SeifertGraph(options: ["physics": true])
        let s = orientationPreservingState
        let D = self.resolved(by: s)
        
        for (i, c) in D.components.enumerated() {
            G.addVertex(id: i, value: c)
        }
        
        func vertex(containing edge: Edge) -> SeifertGraph.Vertex {
            G.vertices.first{ $0.value.value.edges.contains(edge) }!.value
        }
        
        for x in D.crossings {
            let (i, j) = (x.mode == .V) ? (0, 1) : (0, 2)
            let (e1, e2) = (x.edges[i], x.edges[j])
            let v1 = vertex(containing: e1)
            let v2 = vertex(containing: e2)
            v1.addEdge(to: v2, value: x.id)
        }
        
        return G
    }
    
    public static func +(L1: Link, L2: Link) -> Link {
        let dx = (L1.crossings.max()?.id ?? 0) - (L2.crossings.min()?.id ?? 0) + 1
        let de = (L1.edges.max()?.id ?? 0) - (L2.edges.min()?.id ?? 0) + 1
        
        let cL1 = L1.copy()
        let cL2 = L2.copy(diffX: dx, diffE: de)
        
        return Link(name: "\(L1.name) + \(L2.name)", crossings: cL1.crossings + cL2.crossings)
    }
    
    public static func == (lhs: Link, rhs: Link) -> Bool {
        lhs.crossings == rhs.crossings
    }
    
    public var description: String {
        name
    }
    
    public var detailDescription: String {
        "\(name){ \(crossings.map{ $0.description }.joined(separator: ", ")) }"
    }
    
    public final class Crossing: Equatable, Comparable, CustomStringConvertible {
        public enum Mode {
            case X⁻ // 0 - 2 is below 1 - 3
            case X⁺ // 0 - 2 is above 1 - 3
            case V  // 0 - 3 || 1 - 2
            case H  // 0 - 1 || 2 - 3
        }
        
        public let id: Int
        public let edges: [Edge]
        public var mode: Mode
        
        internal init(id: Int, edges e: (Edge, Edge, Edge, Edge), mode: Mode) {
            self.id = id
            self.edges = [e.0, e.1, e.2, e.3]
            self.mode = mode
        }
        
        public var edge0: Edge { edges[0] }
        public var edge1: Edge { edges[1] }
        public var edge2: Edge { edges[2] }
        public var edge3: Edge { edges[3] }
        
        public func adjacentEdge(_ i: Int) -> (index: Int, edge: Edge) {
            let j = { () -> Int in
                switch mode {
                case .X⁻, .X⁺:
                    return (i + 2) % 4
                case .V:
                    return 3 - i
                case .H:
                    return 2 * (i / 2) + (1 - i % 2)
                }
            }()
            return (j, edges[j])
        }
        
        public var isResolved: Bool {
            mode == .V || mode == .H
        }
        
        public var crossingSign: Int {
            if isResolved {
                return 0
            }
            
            let s = { (_ b: Bool) -> Int in b ? 1 : -1 }
            
            return s(edge0.goesIn(to: self, 0))
                 * s(edge1.goesIn(to: self, 1))
                 * s(mode == .X⁺)
        }
        
        public func changeCrossing() {
            switch mode {
            case .X⁻: mode = .X⁺
            case .X⁺: mode = .X⁻
            default: ()
            }
        }
        
        public func resolve(_ s: Bit) {
            switch (mode, s) {
            case (.X⁺, 0), (.X⁻, 1): mode = .V
            case (.X⁺, 1), (.X⁻, 0): mode = .H
            default: ()
            }
        }
        
        public static func ==(c1: Crossing, c2: Crossing) -> Bool {
            c1.edges == c2.edges
        }
        
        public static func <(c1: Crossing, c2: Crossing) -> Bool {
            c1.id < c2.id
        }
        
        public var description: String {
            "\(mode)[\(edge0),\(edge1),\(edge2),\(edge3)]"
        }
    }
    
    public final class Edge: Equatable, Comparable, Hashable, CustomStringConvertible {
        public typealias EndPoint = (crossing: Crossing, index: Int)
        
        public internal(set) var id: Int
        
        internal weak var x0: Crossing! = nil
        private var      i0: Int = 0
        private weak var x1: Crossing! = nil
        private var      i1: Int = 0

        internal init(_ id: Int) {
            self.id = id
        }
        
        public var isDetermined: Bool {
            x0 != nil && x1 != nil
        }
        
        public var endPoint0: EndPoint {
            get { (x0!, i0) }
            set { (x0, i0) = (newValue.0, newValue.1) }
        }
        
        public var endPoint1: EndPoint {
            get { (x1!, i1) }
            set { (x1, i1) = (newValue.0, newValue.1) }
        }
        
        public func reverse() {
            let tmp = endPoint1
            endPoint1 = endPoint0
            endPoint0 = tmp
        }
        
        public func goesOut(from x: Crossing, _ i: Int) -> Bool {
            endPoint0 == (x, i)
        }
        
        public func goesIn(to x: Crossing, _ i: Int) -> Bool {
            endPoint1 == (x, i)
        }
        
        public var nextEdge: Edge {
            x1.adjacentEdge(i1).edge
        }
        
        public var prevEdge: Edge {
            x0.adjacentEdge(i0).edge
        }
        
        public static func ==(e1: Edge, e2: Edge) -> Bool {
            e1.id == e2.id
        }
        
        public static func <(e1: Link.Edge, e2: Link.Edge) -> Bool {
            e1.id < e2.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public var description: String {
            "\(id)"
        }
    }
    
    public final class Component: Equatable, Hashable, Comparable, CustomStringConvertible {
        public let edges: [Edge]
        
        internal init(_ edges: [Edge]) {
            self.edges = edges
        }
        
        public static func == (a: Component, b: Component) -> Bool {
            a.edges == b.edges
        }
        
        public static func < (c1: Link.Component, c2: Link.Component) -> Bool {
            c1.edges.map{ $0.id }.min()! < c2.edges.map{ $0.id }.min()!
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(edges)
        }
        
        public var description: String {
            "(\(edges.map{ "\($0)" }.joined(separator: "-")))"
        }
    }
}
