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
        
        assert(crossings.allSatisfy{ x in x.edges.allSatisfy{ e in e.isDetermined } })
        
        self.init(name: (name ?? "L"), crossings: crossings)
    }
    
    public init(name: String? = nil, pdCode: [Int] ...) {
        self.init(name: name, pdCode: pdCode)
    }
}
