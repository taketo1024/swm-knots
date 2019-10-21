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

import SwiftyMath

public struct Link: Equatable, CustomStringConvertible {
    public typealias PlanarCode = [[Int]]
    public typealias State = [Resolution]

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
        crossings.flatMap{ x in x.edges }.unique().sorted()
    }
    
    private let _components: Cache<[Component]> = .empty
    
    public var components: [Component] {
        _components.useCacheOrSet {
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
    
    public mutating func resolve(_ i: Int, _ s: Resolution) {
        _components.clear()
        crossings[i].resolve(s)
        reorientEdges()
    }
    
    public func resolved(_ i: Int, _ s: Resolution) -> Link {
        var L = self.copy(name: "\(name)\(Format.sub(s.description))")
        L.resolve(i, s)
        return L
    }
    
    public func resolved(by state: State) -> Link {
        let L = self.copy()
        let xs = L.crossings.filter{ !$0.isResolved }
        
        assert(xs.count == state.count)
        
        for (x, s) in zip(xs, state) {
            x.resolve(s)
        }
        L.reorientEdges()
        
        return L
    }
    
    public func resolvedPair(at i: Int) -> (Link, Link) {
        (resolved(i, .resolution0), resolved(i, .resolution1))
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
    
    public var allStates: [State] {
        generateBinarySequences(with: (.resolution0, .resolution1), length: crossingNumber)
    }
    
    public var orientationPreservingState: State {
        State( crossings.compactMap{ x in
            x.isResolved
                ? nil
                : x.crossingSign == 1
                    ? .resolution0 : .resolution1
        } )
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
    
    public enum Resolution: Int8, Comparable, CustomStringConvertible, Codable {
        case resolution0 = 0
        case resolution1 = 1
        
        public init(_ i: Int) {
            self = (i == 0) ? .resolution0 : .resolution1
        }
        
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        public var description: String {
            rawValue.description
        }
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
        
        public func resolve(_ s: Resolution) {
            switch (mode, s) {
            case (.X⁺, .resolution0), (.X⁻, .resolution1): mode = .V
            case (.X⁺, .resolution1), (.X⁻, .resolution0): mode = .H
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

extension Array where Element == Link.Resolution {
    public var weight: Int {
        count(where: { $0 == .resolution1 })
    }
}

internal func generateBinarySequences<T>(with choice: (T, T), length n: Int) -> [[T]] {
    assert(n <= 64)
    return (0 ..< 2.pow(n)).map { (b0: Int) -> [T] in
        var b = b0
        return (0 ..< n).reduce(into: []) { (result, _) in
            result.append( (b & 1 == 0) ? choice.0 : choice.1 )
            b >>= 1
        }
    }
}
