//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

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

import Foundation

extension Link {
    public typealias PDCode = [[Int]]
    public init(name: String? = nil, pdCode: PDCode) {
        
        // generate edges.
        
        let edgeIds = Set(pdCode.flatMap{ $0 })
        let edges = Dictionary(keys: edgeIds) { id in Edge(id) }
        
        // generate crossings.
        
        let crossings = pdCode.enumerated().map { (i, c) -> Crossing in
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
        
        // arbitrarily orient non-oriented edges
        while let x = crossings.first(where: {!$0.edge1.isDetermined}) {
            var e = x.edge1
            e.endPoint0 = (x, 1)
            
            while !e.isDetermined {
                if let y = crossings.first(where: { y in y != e.endPoint0.crossing && y.edge1 == e }) {
                    e.endPoint1 = (y, 1)
                    e = y.edge3
                    e.endPoint0 = (y, 3)
                } else if let y = crossings.first(where: { y in y != e.endPoint0.crossing && y.edge3 == e }) {
                    e.endPoint1 = (y, 3)
                    e = y.edge1
                    e.endPoint0 = (y, 1)
                } else {
                    fatalError()
                }
            }
        }
        
        assert(crossings.allSatisfy{ x in x.edges.allSatisfy{ e in e.isDetermined } })
        
        self.init(name: (name ?? "L"), crossings: crossings)
    }
    
    public init(name: String? = nil, pdCode: [Int] ...) {
        self.init(name: name, pdCode: pdCode)
    }
    
    // The resources are extracted from:
    //
    // - Knot Table  http://katlas.org/wiki/The_Rolfsen_Knot_Table
    // - Link Table  http://katlas.org/wiki/The_Thistlethwaite_Link_Table
    // - Torus Knots http://katlas.org/wiki/36_Torus_Knots

    public static func load(_ name: String) -> Link? {
        #if os(macOS) || os(Linux)
        guard
            let url = Bundle.module.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let code = try? JSONDecoder().decode(Link.PDCode.self, from: data)
        else {
            return nil
        }
        return Link(name: name, pdCode: code)
        #else
        return nil
        #endif
    }
}
