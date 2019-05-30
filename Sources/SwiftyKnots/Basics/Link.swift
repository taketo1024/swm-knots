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
    public typealias PlanarCode = [[Int]]

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
    
    public init(name: String? = nil, planarCode: PlanarCode) {
        
        // generate edges.
        
        let edgeIds = Set(planarCode.flatMap{ $0 })
        let edges = Dictionary(keys: edgeIds) { id in Edge(id) }
        
        // generate crossings.
        
        let crossings = planarCode.enumerated().map { (i, c) -> Crossing in
            let (e0, e1, e2, e3) = (edges[c[0]]!, edges[c[1]]!, edges[c[2]]!, edges[c[3]]!)
            let c = Crossing(id: i, edges: (e0, e1, e2, e3), mode: .X⁻)
            e0.endPoint1 = (c, 0)
            e2.endPoint0 = (c, 2)
            
            return c
        }
        
        // traverse edges and determine orientation
        
        var queue = crossings
            .map{ x in x.edge2 }
            .filter{ e in !e.isDetermined }
        
        while !queue.isEmpty {
            let e = queue.removeFirst()
            let next: Edge

            if let x = crossings.first(where: { x in x.edge1 == e && e.endPoint0 != (x, 1) }) {
                e.endPoint1 = (x, 1)
                next = x.edge3
                next.endPoint0 = (x, 3)
            } else if let x = crossings.first(where: {x in x.edge3 == e && e.endPoint0 != (x, 3) }) {
                e.endPoint1 = (x, 3)
                next = x.edge1
                next.endPoint0 = (x, 1)
            } else {
                fatalError()
            }
            
            if !next.isDetermined {
                queue.insert(next, at: 0)
            }
        }
        
        assert(crossings.allSatisfy{ x in x.edges.allSatisfy{ e in e.isDetermined } })
        
        self.init(name: (name ?? "L"), crossings: crossings)
    }
    
    public init(name: String? = nil, planarCode: [Int] ...) {
        self.init(name: name, planarCode: planarCode)
    }
    
    public func copy(name: String? = nil, diffX: Int = 0, diffE: Int = 0) -> Link {
        let myEdges = Dictionary(pairs: edges.map{ e in (e.id, e) })
        let cpEdges = myEdges.mapPairs{ (id, _) in (id, Edge(id + diffE)) }
        let cpCross = Dictionary(pairs: crossings.map { x -> (Int, Crossing) in
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
    
    public func crossingChanged(at i: Int) -> Link {
        let L = self.copy(name: "\(name)'")
        L.crossings[i].changeCrossing()
        return L
    }
    
    public var edges: [Edge] {
        return crossings.flatMap{ x in x.edges }.unique().sorted()
    }
    
    private let _components: Cache<[Component]> = .empty
    
    public var components: [Component] {
        return _components.useCacheOrSet {
            var queue = edges
            var comps: [Component] = []
            
            while !queue.isEmpty {
                var comp: [Edge] = []
                
                let first = queue.first!
                var e = first
                
                while queue.contains(e) {
                    queue.remove(element: e)
                    comp.append(e)
                    e = e.nextEdge
                }
                
                assert(e == first)
                
                comps.append(Component(comp))
            }
            
            return comps
        }
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
    
    private mutating func _splice(at i: Int, type: Int) {
        switch type {
        case 0: crossings[i].splice0()
        case 1: crossings[i].splice1()
        default: ()
        }
    }
    
    @discardableResult
    public mutating func splice(at i: Int, type: Int) -> Link {
        _components.clear()
        _splice(at: i, type: type)
        reorientEdges()
        return self
    }
    
    public func spliced(at i: Int, type: Int) -> Link {
        var L = self.copy(name: "\(name)\(Format.sub(type.description))")
        return L.splice(at: i, type: type)
    }
    
    public func spliced(by state: [Int]) -> Link {
        var L = self.copy()
        for (i, s) in state.enumerated() {
            L._splice(at: i, type: s)
        }
        L.reorientEdges()
        return L
    }
    
    public func spliced(by state: IntList) -> Link {
        return spliced(by: state.components)
    }
    
    public func splicedPair(at i: Int) -> (Link, Link) {
        return (self.spliced(at: i, type: 0), self.spliced(at: i, type: 1))
    }
    
    private func reorientEdges() {
        var queue = edges
        while !queue.isEmpty {
            let first = queue.first!
            var e = first
            
            while queue.contains(e) {
                queue.remove(element: e)
                
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
    
    public var allStates: [IntList] {
        return IntList.binaryCombinations(length: crossingNumber)
            .sorted{ $0.total < $1.total }
    }
    
    public static func +(L1: Link, L2: Link) -> Link {
        let dx = (L1.crossings.max()?.id ?? 0) - (L2.crossings.min()?.id ?? 0) + 1
        let de = (L1.edges.max()?.id ?? 0) - (L2.edges.min()?.id ?? 0) + 1
        
        let cL1 = L1.copy()
        let cL2 = L2.copy(diffX: dx, diffE: de)
        
        return Link(name: "\(L1.name) + \(L2.name)", crossings: cL1.crossings + cL2.crossings)
    }
    
    public static func == (lhs: Link, rhs: Link) -> Bool {
        return lhs.crossings == rhs.crossings
    }
    
    public var description: String {
        return name
    }
    
    public var detailDescription: String {
        return "\(name){ \(crossings.map{ $0.description }.joined(separator: ", ")) }"
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
        
        public let id: Int
        public let edges: [Edge]
        public var mode: Mode
        
        internal init(id: Int, edges e: (Edge, Edge, Edge, Edge), mode: Mode) {
            self.id = id
            self.edges = [e.0, e.1, e.2, e.3]
            self.mode = mode
        }
        
        public var edge0: Edge { return edges[0] }
        public var edge1: Edge { return edges[1] }
        public var edge2: Edge { return edges[2] }
        public var edge3: Edge { return edges[3] }
        
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
        
        public var isCrossing: Bool {
            return mode.isCrossing
        }
        
        public var crossingSign: Int {
            if !isCrossing {
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
        
        public func splice0() {
            switch mode {
            case .X⁺: mode = .V
            case .X⁻: mode = .H
            default: ()
            }
        }
        
        public func splice1() {
            switch mode {
            case .X⁺: mode = .H
            case .X⁻: mode = .V
            default: ()
            }
        }
        
        public static func ==(c1: Crossing, c2: Crossing) -> Bool {
            return c1.edges == c2.edges
        }
        
        public static func <(c1: Crossing, c2: Crossing) -> Bool {
            return c1.id < c2.id
        }
        
        public var description: String {
            return "\(mode)[\(edge0),\(edge1),\(edge2),\(edge3)]"
        }
    }
    
    public class Edge: Equatable, Comparable, Hashable, CustomStringConvertible {
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
            return x0 != nil && x1 != nil
        }
        
        public var endPoint0: EndPoint {
            get { return (x0!, i0) }
            set { (x0, i0) = (newValue.0, newValue.1) }
        }
        
        public var endPoint1: EndPoint {
            get { return (x1!, i1) }
            set { (x1, i1) = (newValue.0, newValue.1) }
        }
        
        public func reverse() {
            let tmp = endPoint1
            endPoint1 = endPoint0
            endPoint0 = tmp
        }
        
        public func goesOut(from x: Crossing, _ i: Int) -> Bool {
            return endPoint0 == (x, i)
        }
        
        public func goesIn(to x: Crossing, _ i: Int) -> Bool {
            return endPoint1 == (x, i)
        }
        
        public var nextEdge: Edge {
            return x1.adjacentEdge(i1).edge
        }
        
        public var prevEdge: Edge {
            return x0.adjacentEdge(i0).edge
        }
        
        public static func ==(e1: Edge, e2: Edge) -> Bool {
            return e1.id == e2.id
        }
        
        public static func <(e1: Link.Edge, e2: Link.Edge) -> Bool {
            return e1.id < e2.id
        }
        
        public var hashValue: Int {
            return id
        }
        
        public var description: String {
            return "\(id)"
        }
    }
    
    public class Component: Equatable, Hashable, Comparable, CustomStringConvertible {
        public let edges: [Edge]
        
        internal init(_ edges: [Edge]) {
            self.edges = edges
        }
        
        public static func == (a: Component, b: Component) -> Bool {
            return a.edges == b.edges
        }
        
        public static func < (c1: Link.Component, c2: Link.Component) -> Bool {
            return c1.edges.map{ $0.id }.min()! < c2.edges.map{ $0.id }.min()!
        }
        
        public var hashValue: Int {
            return edges.hashValue
        }
        
        public var description: String {
            return "(\(edges.map{ "\($0)" }.joined(separator: "-")))"
        }
    }
}
