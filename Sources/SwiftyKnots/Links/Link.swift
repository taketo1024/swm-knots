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

import Foundation
import SwiftyMath

public struct Link: CustomStringConvertible {
    
    /* Planer Diagram code, represented by crossings:
     *
     *    3   2
     *     \ /
     *      \      = (0, 1, 2, 3)
     *     / \
     *    0   1
     *
     * The lower edge has direction 0 -> 2.
     * The crossing is +1 if the upper goes 3 -> 1.
     *
     * see: http://katlas.math.toronto.edu/wiki/Planar_Diagrams
     */
    
    internal let junctions: [Junction]
    
    internal init(_ junctions: [Junction]) {
        self.junctions = junctions
    }
    
    public init(planarCode: (Int, Int, Int, Int) ...) {
        
        // generate edges.
        
        var edges = [Int : Edge]()
        for edgeId in planarCode.flatMap( {[$0.0, $0.1, $0.2, $0.3]} ) {
            if edges[edgeId] == nil {
                edges[edgeId] = Edge(edgeId)
            }
        }
        
        // generate junctions.
        
        let junctions = planarCode.map { c -> Junction in
            let (e0, e1, e2, e3) = (edges[c.0]!, edges[c.1]!, edges[c.2]!, edges[c.3]!)
            assert(e0.to == nil)
            assert(e2.from == nil)
            
            let J = Junction(edges: (e0, e1, e2, e3), mode: .X⁻)
            e0.to = J
            e2.from = J
            
            return J
        }
        
        // traverse edges and determine orientation
        
        var queue = junctions.map{ $0.edge2 }.filter{ $0.to == nil }
        while !queue.isEmpty {
            let e = queue.removeFirst()
            let nextE: Edge
            let nextJ: Junction
            
            if let J = junctions.first(where: { $0.edge1 == e } ) {
                nextJ = J
                nextE = J.edge3
            } else if let J = junctions.first(where: { $0.edge3 == e } ) {
                nextJ = J
                nextE = J.edge1
            } else {
                fatalError()
            }
            
            e.to       = nextJ
            nextE.from = nextJ
            
            if nextE.to == nil {
                queue.insert(nextE, at: 0)
            }
        }
        
        for J in junctions {
            J.edges.forEach { e in
                assert(e.from != nil)
                assert(e.to   != nil)
            }
        }
        
        self.init(junctions)
    }
    
    public static var empty: Link {
        return Link([])
    }
    
    public static var unknot: Link {
        let (e0, e1) = (Edge(0), Edge(1))
        let J = Junction(edges: (e0, e0, e1, e1), mode: .V)
        e0.from = J
        e0.to   = J
        e1.from = J
        e1.to   = J
        return Link([J])
    }
    
    private var allEdges: Set<Edge> {
        return Set( junctions.flatMap{ J -> [Edge] in J.edges } )
    }
    
    public func copy() -> Link {
        let edges = Dictionary(pairs: allEdges.map{ e -> (Int, Edge) in (e.id, e) } )
        
        let copiedEdges = edges.mapValues{ e in Edge(e.id) }
        let copiedJuncs = junctions.map { J -> Junction in
            let edges = J.edges.map{ copiedEdges[$0.id]! }
            return Junction(edges: (edges[0], edges[1], edges[2], edges[3]), mode: J.mode)
        }
        
        for (id, e) in copiedEdges {
            let orig = edges[id]!
            e.from = copiedJuncs[ junctions.index(of: orig.from)! ]
            e.to   = copiedJuncs[ junctions.index(of: orig.to  )! ]
        }
        
        return Link(copiedJuncs)
    }
    
    public var components: Int {
        var queue = allEdges
        var res = 0
        
        while !queue.isEmpty {
            res += 1
            var e = queue.anyElement!
            var J = e.to!
            
            while queue.contains(e) {
                queue.remove(e)
                e = J.adjacent(e)
                J = e.opposite(J)
            }
        }
        
        return res
    }
    
    public var crossingNumber: Int {
        return junctions.sum { J in J.isCrossing ? 1 : 0 }
    }
    
    public var writhe: Int {
        return junctions.sum { J in J.crossingSign }
    }
    
    public var reversed: Link {
        let L = self.copy()
        for e in L.allEdges {
            e.reverse()
        }
        return L
    }
    
    public var mirrored: Link {
        let L = self.copy()
        for J in L.junctions {
            J.changeCrossing()
        }
        return L
    }
    
    public static func +(L1: Link, L2: Link) -> Link {
        let cL1 = L1.copy()
        let cL2 = L2.copy()
        let D = (cL1.allEdges.max()?.id ?? 0) - (cL2.allEdges.min()?.id ?? 0) + 1
        for e in cL2.allEdges {
            e.id += D
        }
        return Link(cL1.junctions + cL2.junctions)
    }
    
    /*
     *     \ /          \ /
     *      /      ==>  | |
     *     / \          / \
     */
    
    @discardableResult
    public mutating func spliceA(at n: Int) -> Link {
        junctions[n].spliceA()
        return self
    }
    
    public func splicedA(at n: Int) -> Link {
        var L = self.copy()
        L.spliceA(at: n)
        return L
    }
    
    /*
     *     \ /          \_/
     *      /      ==>
     *     / \          /‾\
     */
    
    @discardableResult
    public mutating func spliceB(at n: Int) -> Link {
        junctions[n].spliceB()
        return self
    }
    
    public func splicedB(at n: Int) -> Link {
        var L = self.copy()
        L.spliceB(at: n)
        return L
    }
    
    public func splicedPair(at i: Int) -> (Link, Link) {
        return (splicedA(at: i), splicedB(at: i))
    }
    
    public var description: String {
        return "L{ \(junctions.map{ $0.description }.joined(separator: ", ")) }"
    }
    
    public class Edge: Equatable, Comparable, Hashable, CustomStringConvertible {
        public internal(set) var id: Int
        
        public weak var from: Junction! = nil
        public weak var to  : Junction! = nil
        
        internal init(_ id: Int) {
            self.id = id
        }
        
        public func reverse() {
            let tmp = to
            to = from
            from = tmp
        }
        
        public func goesIn(to v: Junction) -> Bool {
            return to == v
        }
        
        public func goesOut(from v: Junction) -> Bool {
            return from == v
        }
        
        public func opposite(_ v: Junction) -> Junction {
            return (from == v) ? to : from
        }
        
        public var nextEdge: Edge {
            return to.adjacent(self)
        }
        
        public var prevEdge: Edge {
            return from.adjacent(self)
        }
        
        public static func ==(e1: Edge, e2: Edge) -> Bool {
            return e1 === e2
        }
        
        public static func <(e1: Link.Edge, e2: Link.Edge) -> Bool {
            return e1.id < e2.id
        }
        
        public var hashValue: Int {
            return id.hashValue
        }
        
        public var description: String {
            return "\(id)"
        }
    }
    
    public class Junction: Equatable, Comparable, CustomStringConvertible {
        public enum Mode {
            case X⁺ // 0 - 2 is above 1 - 3
            case X⁻ // 0 - 2 is below 1 - 3
            case V  // 0 - 3 || 1 - 2
            case H  // 0 - 1 || 2 - 3
            
            public var isCrossing: Bool {
                return self == .X⁺ || self == .X⁻
            }
        }
        
        fileprivate let edges: [Edge]
        public var mode: Mode
        
        internal init(edges e: (Edge, Edge, Edge, Edge), mode: Mode) {
            self.edges = [e.0, e.1, e.2, e.3]
            self.mode = mode
        }
        
        public var edge0: Edge { return edges[0] }
        public var edge1: Edge { return edges[1] }
        public var edge2: Edge { return edges[2] }
        public var edge3: Edge { return edges[3] }
        
        public func position(of e: Edge) -> Int {
            return edges.index(of: e)!
        }
        
        public func adjacent(_ e: Edge) -> Edge {
            let i = position(of: e)
            switch mode {
            case .X⁻, .X⁺:
                return edges[(i + 2) % 4]
            case .V:
                switch i {
                case 0: return edge3
                case 1: return edge2
                case 2: return edge1
                case 3: return edge0
                default: ()
                }
            case .H:
                switch i {
                case 0: return edge1
                case 1: return edge0
                case 2: return edge3
                case 3: return edge2
                default: ()
                }
            }
            fatalError()
        }
        
        public var isCrossing: Bool {
            return mode.isCrossing
        }
        
        public var crossingSign: Int {
            func s(_ b: Bool) -> Int {
                return b ? 1 : -1
            }
            
            if !isCrossing {
                return 0
            }
            
            return s(edge0.goesIn(to: self))
                * s(edge1.goesIn(to: self))
                * s(mode == .X⁺)
        }
        
        public func changeCrossing() {
            switch mode {
            case .X⁺: mode = .X⁻
            case .X⁻: mode = .X⁺
            default: ()
            }
        }
        
        public func spliceA() {
            switch mode {
            case .X⁺: mode = .V
            case .X⁻: mode = .H
            default: fatalError()
            }
        }
        
        public func spliceB() {
            changeCrossing()
            spliceA()
        }
        
        private func reorientEgdes(startingFrom e0: Edge) {
            // TODO
        }
        
        public static func ==(c1: Junction, c2: Junction) -> Bool {
            return c1 === c2
        }
        
        public static func <(e1: Junction, e2: Junction) -> Bool {
            return e1.edges.lexicographicallyPrecedes(e2.edges)
        }
        
        public var description: String {
            return "\(mode)[\(edge0),\(edge1),\(edge2),\(edge3)]"
        }
    }
}
