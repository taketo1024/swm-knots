//
//  KhHomologyExtensions.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/05/31.
//

import Foundation
import SwiftyMath

extension Link {
    public func LeeCycles<R: Ring>(_ type: R.Type, _ c: R) -> [FreeModule<KhEnhancedState, R>] {
        return LeeCycles(R.self, .zero, c)
    }
    
    public func LeeCycles<R: Ring>(_ type: R.Type, _ u: R, _ v: R) -> [FreeModule<KhEnhancedState, R>] {
        typealias Component = Link.Component
        
        assert(components.count == 1) // currently supports only knots.
        
        let s0 = orientationPreservingState
        let L0 = spliced(by: s0)
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
        
        typealias A = FreeModule<FreeTensor<KhEnhancedState.E>, R>
        
        let (X, I) = (A.wrap(FreeTensor(.X)), A.wrap(FreeTensor(.I)))
        let (a, b) = (X - u * I, X - v * I)
        var (z0, z1) = (A.wrap(FreeTensor()), A.wrap(FreeTensor()))
        
        for c in comps {
            switch result[c]! {
            case 0:
                z0 = z0 ⊗ a
                z1 = z1 ⊗ b
            default:
                z0 = z0 ⊗ b
                z1 = z1 ⊗ a
            }
        }
        
        return [z0, z1].map { z in
            z.convertGenerators{ t in KhEnhancedState(s0, t) }
        }
    }
    
    public func LeeClassDivisibility<R: EuclideanRing>(_ type: R.Type, _ c: R) -> Int {
        let K = self
        let C = K.KhovanovChainComplex(R.self, h: c, t: .zero)
        let H0 = C.homology(0).freePart
        let a = K.LeeCycles(R.self, c)[0]
        
        var k = 0
        var v = H0.factorize(a)
        
        while (v[0] % c, v[1] % c) == (.zero, .zero) {
            v = [v[0] / c, v[1] / c]
            k += 1
        }
        
        return k
    }
    
    public func sHatInvariant<R: EuclideanRing>(_ type: R.Type, _ c: R) -> Int {
        let K = self
        let k = K.LeeClassDivisibility(R.self, c)
        let r = K.spliced(by: K.orientationPreservingState).components.count
        let w = K.writhe
        let s = 2 * k - r + w + 1
        return s
    }

}
