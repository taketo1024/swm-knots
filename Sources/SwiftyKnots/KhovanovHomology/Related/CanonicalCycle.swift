//
//  CanonicalCycle.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2019/10/11.
//

import SwiftyMath
import SwiftyHomology

extension KhovanovComplex {
    private enum CanonicalCycleColor {
        case a, b
        
        var inverse: CanonicalCycleColor {
            return (self == .a) ? .b : .a
        }
    }
    
    public var canonicalCycles: (BaseModule, BaseModule) {
        assert(link.components.count == 1) // currently supports only knots.
        
        typealias E = LinearCombination<MultiTensorGenerator<KhovanovAlgebraGenerator>, R>
        
        let (X, I) = (wrap(.X), wrap(.I))
        let (u, v) = (cube.type.u, cube.type.v)
        let (a, b) = (X - u * I, X - v * I)

        var α = E.wrap(.identity)
        var β = E.wrap(.identity)

        for (_, color) in coloredSeifertCircles {
            α = α ⊗ ( (color == .a) ? a : b)
            β = β ⊗ ( (color == .a) ? b : a)
        }
        
        let s0 = link.orientationPreservingState
        return (
            BaseModule(index: s0, value: α),
            BaseModule(index: s0, value: β)
        )
    }
    
    private var coloredSeifertCircles: [(Link.Component, CanonicalCycleColor)] {
        typealias Circle = Link.Component
        
        let s0 = link.orientationPreservingState
        let L0 = link.resolved(by: s0)
        let circles = L0.components

        // color each circle in a / b.
        var queue:  [(Circle, CanonicalCycleColor)] = [(circles[0], .a)]
        var result:  [Circle : CanonicalCycleColor] = [:]

        while !queue.isEmpty {
            let (circle, color) = queue.removeFirst()

            // crossings that touches c
            let xs = link.crossings.filter{ x in
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

        return circles.map { c in (c, result[c]!) }
    }
    
    private func wrap(_ x: KhovanovAlgebraGenerator) -> LinearCombination<MultiTensorGenerator<KhovanovAlgebraGenerator>, R> {
        .wrap( MultiTensorGenerator([x]) )
    }
}
