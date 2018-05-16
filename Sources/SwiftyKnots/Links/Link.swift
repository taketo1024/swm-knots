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

public struct Link: Equatable, CustomStringConvertible {
    
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
    
    public let name: String
    internal let crossings: [Crossing]
    
    internal init(name: String, crossings: [Crossing]) {
        self.name = name
        self.crossings = crossings
    }
    
    public init(name: String? = nil, planarCode: [[Int]]) {
        
        // generate edges.
        
        let edgeIds = Set(planarCode.flatMap{ $0 })
        let edges = Dictionary(keys: edgeIds) { id in Edge(id) }
        
        // generate crossings.
        
        let crossings = planarCode.map { c -> Crossing in
            let (e0, e1, e2, e3) = (edges[c[0]]!, edges[c[1]]!, edges[c[2]]!, edges[c[3]]!)
            assert(e0.to == nil)
            assert(e2.from == nil)
            
            let c = Crossing(edges: (e0, e1, e2, e3), mode: .X⁻)
            e0.to = c
            e2.from = c
            
            return c
        }
        
        // traverse edges and determine orientation
        
        var queue = crossings.map{ $0.edge2 }.filter{ $0.to == nil }
        while !queue.isEmpty {
            let e = queue.removeFirst()
            let nextE: Edge
            let nextX: Crossing
            
            let match1 = { (x: Crossing) in x != e.from && x.edge1 == e }
            let match3 = { (x: Crossing) in x != e.from && x.edge3 == e }

            if let x = crossings.first(where: match1) {
                nextX = x
                nextE = x.edge3
            } else if let x = crossings.first(where: match3) {
                nextX = x
                nextE = x.edge1
            } else {
                fatalError()
            }
            
            e.to       = nextX
            nextE.from = nextX
            
            if nextE.to == nil {
                queue.insert(nextE, at: 0)
            }
        }
        
        for x in crossings {
            x.edges.forEach { e in
                assert(e.from != nil)
                assert(e.to   != nil)
            }
        }
        
        self.init(name: (name ?? "L"), crossings: crossings)
    }
    
    public init(name: String? = nil, planarCode: [Int] ...) {
        self.init(name: name, planarCode: planarCode)
    }
    
    public func copy(name: String? = nil) -> Link {
        let edges = Dictionary(pairs: self.edges.map{ e -> (Int, Edge) in (e.id, e) } )
        
        let copiedEdges = edges.mapValues{ e in Edge(e.id) }
        let copiedCross = crossings.map { x -> Crossing in
            let edges = x.edges.map{ copiedEdges[$0.id]! }
            return Crossing(edges: (edges[0], edges[1], edges[2], edges[3]), mode: x.mode)
        }
        
        for (id, e) in copiedEdges {
            let orig = edges[id]!
            e.from = copiedCross[ crossings.index(of: orig.from)! ]
            e.to   = copiedCross[ crossings.index(of: orig.to  )! ]
        }
        
        return Link(name: name ?? self.name, crossings: copiedCross)
    }
    
    public var edges: Set<Edge> {
        return Set( crossings.flatMap{ x -> [Edge] in x.edges } )
    }
    
    public var components: [Component] {
        var queue = edges.sorted()
        var comps = [Component]()
        
        while !queue.isEmpty {
            var c = [Edge]()
            var e = queue.first!
            var x = e.to!
            
            while queue.contains(e) {
                queue.remove(element: e)
                c.append(e)
                e = x.adjacent(e)
                x = e.opposite(x)
            }
            
            comps.append(Component(c))
        }
        
        return comps
    }
    
    public var crossingNumber: Int {
        return crossings.count { x in x.isCrossing }
    }
    
    public var crossingNumber⁺: Int {
        return crossings.count { x in x.crossingSign == 1 }
    }
    
    public var crossingNumber⁻: Int {
        return crossings.count { x in x.crossingSign == -1 }
    }
    
    public var writhe: Int {
        return crossings.sum { x in x.crossingSign }
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
    
    public var planarCode: [[Int]] {
        return crossings.map { c -> [Int] in
            switch c.mode {
            case .X⁻:
                if c.edge0.to == c {
                    return [c.edge0.id, c.edge1.id, c.edge2.id, c.edge3.id]
                } else if c.edge2.to == c {
                    return [c.edge2.id, c.edge3.id, c.edge0.id, c.edge1.id]
                }
                fallthrough
                
            case .X⁺:
                if c.edge1.to == c {
                    return [c.edge1.id, c.edge2.id, c.edge3.id, c.edge0.id]
                } else if c.edge3.to == c {
                    return [c.edge3.id, c.edge0.id, c.edge1.id, c.edge2.id]
                }
                fallthrough
                
            default:
                fatalError()
            }
        }
    }
    
    public static func +(L1: Link, L2: Link) -> Link {
        let cL1 = L1.copy()
        let cL2 = L2.copy()
        let D = (cL1.edges.max()?.id ?? 0) - (cL2.edges.min()?.id ?? 0) + 1
        for e in cL2.edges {
            e.id += D
        }
        return Link(name: "\(L1.name) + \(L2.name)", crossings: cL1.crossings + cL2.crossings)
    }
    
    public var description: String {
        return name
    }
    
    public var detailDescription: String {
        return "\(name){ \(crossings.map{ $0.description }.joined(separator: ", ")) }"
    }
    
    public class Edge: Equatable, Comparable, Hashable, CustomStringConvertible {
        public internal(set) var id: Int
        
        public weak var from: Crossing! = nil
        public weak var to  : Crossing! = nil
        
        internal init(_ id: Int) {
            self.id = id
        }
        
        public func reverse() {
            let tmp = to
            to = from
            from = tmp
        }
        
        public func goesIn(to v: Crossing) -> Bool {
            return to == v
        }
        
        public func goesOut(from v: Crossing) -> Bool {
            return from == v
        }
        
        public func opposite(_ v: Crossing) -> Crossing {
            return (from == v) ? to : from
        }
        
        public var nextEdge: Edge {
            return to.adjacent(self)
        }
        
        public var prevEdge: Edge {
            return from.adjacent(self)
        }
        
        public static func ==(e1: Edge, e2: Edge) -> Bool {
            return e1.id == e2.id
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
    
    public class Component: Equatable, CustomStringConvertible {
        public static func == (a: Component, b: Component) -> Bool {
            return a.edges == b.edges
        }
        
        public var description: String {
            return "(\(edges.map{ "\($0)" }.joined(separator: "-")))"
        }
        
        public let edges: [Edge]
        internal init(_ edges: [Edge]) {
            assert(edges.count >= 2)
//            assert(edges.first!.from == edges.last!.to)
            self.edges = edges.sorted()
        }
    }
    
    public class Crossing: Equatable, Comparable, CustomStringConvertible {
        public enum Mode {
            case X⁻ // 0 - 2 is below 1 - 3
            case X⁺ // 0 - 2 is above 1 - 3
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
            case .X⁻: mode = .X⁺
            case .X⁺: mode = .X⁻
            default: ()
            }
        }
        
        public func splice0() {
            switch mode {
            case .X⁺: mode = .V
            case .X⁻: mode = .H
            default: fatalError()
            }
        }
        
        public func splice1() {
            switch mode {
            case .X⁺: mode = .H
            case .X⁻: mode = .V
            default: fatalError()
            }
        }
        
        private func reorientEgdes(startingFrom e0: Edge) {
            // TODO
        }
        
        public static func ==(c1: Crossing, c2: Crossing) -> Bool {
            return c1.edges == c2.edges
        }
        
        public static func <(e1: Crossing, e2: Crossing) -> Bool {
            return e1.edges.lexicographicallyPrecedes(e2.edges)
        }
        
        public var description: String {
            return "\(mode)[\(edge0),\(edge1),\(edge2),\(edge3)]"
        }
    }
}

extension Link: Codable {
    enum CodingKeys: String, CodingKey {
        case name, planarCode
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let name = try c.decode(String.self, forKey: .name)
        let code = try c.decode([[Int]].self, forKey: .planarCode)
        self.init(name: name, planarCode: code)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(planarCode, forKey: .planarCode)
    }
}
