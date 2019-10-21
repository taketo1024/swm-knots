//
//  CanonicalCycle.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2019/10/11.
//

import SwiftyMath
import SwiftyHomology

extension ChainComplex where GridDim == _1, BaseModule: FreeModuleType, BaseModule.Generator == KhComplexGenerator {
    private enum CanonicalCycleColor {
        case a, b
        
        var inverse: CanonicalCycleColor {
            return (self == .a) ? .b : .a
        }
    }
    
    public func canonicalCycle(_ L: Link, c: R) -> KhovanovComplex<R>.Element {
        return LeeCycle(L, u: .zero, v: c)
    }

    public func LeeCycle(_ L: Link, u: R = -R.identity, v: R = R.identity) -> KhovanovComplex<R>.Element {
        assert(L.components.count == 1) // currently supports only knots.

        let s0 = L.orientationPreservingState
        let L0 = L.resolved(by: s0)
        
        typealias Circle = Link.Component
        let circles = L0.components

        // color each circle in a / b.
        var queue:  [(Circle, CanonicalCycleColor)] = [(circles[0], .a)]
        var result:  [Circle : CanonicalCycleColor] = [:]

        while !queue.isEmpty {
            let (circle, color) = queue.removeFirst()

            // crossings that touches c
            let xs = L.crossings.filter{ x in
                !x.isResolved && x.edges.contains{ e in circle.edges.contains(e) }
            }

            // circles that are connected to c by xs
            let cs = xs.map{ x -> Circle in
                let e = x.edges.first{ e in !circle.edges.contains(e) }!
                return circles.first{ c1 in c1.edges.contains(e) }!
            }.unique()

            // queue circles with opposite color.
            for c1 in cs where !result.contains(key: c1) {
                queue.append((c1, color.inverse))
            }

            // append result.
            result[circle] = color
        }

        assert(result.count == circles.count)

        typealias Element = KhovanovComplex<R>.Element
        typealias A = Element.Generator
        
        func wrap(_ x: KhAlgebraGenerator) -> Element {
            .wrap( Element.Generator(tensor: MultiTensorGenerator([x]), state: []))
        }

        let (X, I) = (wrap(.X), wrap(.I))
        let (a, b) = (X - u * I, X - v * I)
        var z = Element.wrap( Element.Generator(tensor: .identity, state: s0))

        for c in circles {
            z = z ⊗ ( (result[c]! == .a) ? a : b)
        }

        return z
    }
}
