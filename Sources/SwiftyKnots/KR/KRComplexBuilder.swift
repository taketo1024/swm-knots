//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

import SwiftyMath

public class KRComplexBuilder {
    struct _x: PolynomialIndeterminate {
        public static let degree = 2
        public static var symbol = "x"
    }
    typealias _xn = InfiniteVariatePolynomialIndeterminates<_x>
    typealias R = MultivariatePolynomial<_xn, 𝐐>

    let L: Link
    var table: [Int : Generator]
    
    public init(_ L: Link) {
        self.L = L
        self.table = [:]
        prepare()
    }
    
    private func prepare() {
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
        let vertices = path.map{ vertex($0) }
        
        func traverse(from: Link.Edge, to: Link.Edge) -> R {
            let N = path.count // == 2 * n
            let i = path.firstIndex(of: from)!
            let j = path.firstIndex(of: to)!
            let l = (i < j) ? (j - i) : (j - i + N)
            return (i ..< i + l).sum { vertices[$0 % N] }
        }
        
        for c in 0 ..< n {
            let x = D.crossings[c]
            let rotated = isRotated(x)
            let (i, k, l) = !rotated
                ? (x.edge0, x.edge3, x.edge2)
                : (x.edge3, x.edge2, x.edge1)
            
            let g = Generator(
                ik: traverse(from: i, to: k),
                il: traverse(from: i, to: l)
            )
            
            table[c] = g
        }
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

    private func vertex(_ e: Link.Edge) -> R {
        let x = e.endPoint1.crossing
        let rotated = isRotated(x)
        switch (rotated, e) {
        case (false, x.edge0),
             ( true, x.edge3):
            return R.indeterminate(x.id)
        case (false, x.edge1),
             ( true, x.edge0):
            return -R.indeterminate(x.id)
        default:
            fatalError("impossible")
        }
    }

    struct Generator: CustomStringConvertible {
        let ik: R
        let il: R
        
        var description: String {
            "\((ik: ik, il: il))"
        }
    }
}
