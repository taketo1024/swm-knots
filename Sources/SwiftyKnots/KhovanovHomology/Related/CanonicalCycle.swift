//
//  CanonicalCycle.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2019/10/11.
//

import SwiftyMath

extension Link {
    public func canonicalCycle<R: Ring>(_ c: R) -> KhovanovComplex<R>.Element {
        return canonicalCycle(.zero, c)
    }

    public func canonicalCycle<R: Ring>(_ u: R, _ v: R) -> KhovanovComplex<R>.Element {
        typealias Component = Link.Component

        assert(components.count == 1) // currently supports only knots.

        let s0 = orientationPreservingState
        let L0 = resolved(by: s0)
        let comps = L0.components

        // splits comps into two groups.
        var queue:  [(Component, Int)] = [(comps[0], 0)]
        var result:  [Component : Int] = [:]

        while !queue.isEmpty {
            let (c, i) = queue.removeFirst()

            // crossings that touches c
            let xs = crossings.filter{ x in
                x.edges.contains{ e in c.edges.contains(e) }
            }

            // circles that are connected to c by xs
            let cs = xs.map{ x -> Component in
                let e = x.edges.first{ e in !c.edges.contains(e) }!
                return comps.first{ c1 in c1.edges.contains(e) }!
                }.unique()

            // queue circles with opposite color.
            for c1 in cs where !result.contains(key: c1) {
                queue.append((c1, 1 - i))
            }

            // append result.
            result[c] = i
        }

        assert(result.count == comps.count)

        typealias Element = KhovanovComplex<R>.Element
        typealias A = Element.Generator
        
        func wrap(_ x: KhAlgebraGenerator) -> Element {
            .wrap( Element.Generator(tensor: MultiTensorGenerator([x]), state: []))
        }

        let (X, I) = (wrap(.X), wrap(.I))
        let (a, b) = (X - u * I, X - v * I)
        var z = Element.wrap( Element.Generator(tensor: .identity, state: s0))

        for c in comps {
            z = z ⊗ ( result[c]! == 0 ? a : b)
        }

        return z
    }
}
