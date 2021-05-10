//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

import SwiftyMath
import SwiftyHomology

internal class KREdgeConnection<R: Ring> {
    let L: Link
    
    init(_ L: Link) {
        self.L = L
    }
    
    func compute() -> [Int : KR.EdgeConnection<R>] {
        var connection: [Int : KR.EdgeConnection<R>] = [:]
        
        let n = L.crossingNumber
        let res = L.orientationPreservingState
        
        let G = L.seifertGraph
        let T = G.spanningTree()
        let S = Set(T.collectEdges().map{ $0.value })

        var D = L.copy()
        for c in 0 ..< n where !S.contains(c) {
            D.resolve(c, res[c])
        }
        
        assert(D.components.count == 1)
        let path = D.components[0].edges
        let mPath = path.map{ e in monomial(at: e) }
        
        func traverse(from: Link.Edge, to: Link.Edge) -> KR.EdgeRing<R> {
            let N = path.count // == 2 * n
            let i = path.firstIndex(of: from)!
            let j = path.firstIndex(of: to)!
            let l = (i < j) ? (j - i) : (j - i + N)
            return (i ..< i + l).sum { mPath[$0 % N] }
        }
        
        for c in 0 ..< n {
            let x = D.crossings[c]
            let rotated = isRotated(x)
            let (i, k, l) = !rotated
                ? (x.edge0, x.edge3, x.edge2)
                : (x.edge3, x.edge2, x.edge1)
            
            let g = KR.EdgeConnection(
                ik: traverse(from: i, to: k),
                il: traverse(from: i, to: l)
            )
            
            connection[c] = g
        }
        
        return connection
    }

    /*
     *    k   l
     *     \ /
     *      X
     *     / \
     *    i   j
     */
    private func isRotated(_ x: Link.Crossing) -> Bool {
        switch (x.mode, x.crossingSign) {
        case (.X⁻, -1), (.X⁺, +1), (.V, _):
            return false
        case (.X⁻, +1), (.X⁺, -1), (.H, _):
            return true
        default:
            fatalError("impossible")
        }
    }

    private func monomial(at e: Link.Edge) -> KR.EdgeRing<R> {
        typealias P = KR.EdgeRing<R>
        let x = e.endPoint1.crossing
        let rotated = isRotated(x)
        switch (rotated, e) {
        case (false, x.edge0),
             ( true, x.edge3):
            return P.indeterminate(x.id)
        case (false, x.edge1),
             ( true, x.edge0):
            return -P.indeterminate(x.id)
        default:
            fatalError("impossible")
        }
    }
}
