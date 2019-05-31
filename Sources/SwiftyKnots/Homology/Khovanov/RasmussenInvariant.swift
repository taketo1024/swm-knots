//
//  RasmussenInvariant.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/05/31.
//

import Foundation

extension Link {
    public var RasmussenInvariant: Int {
        return RasmussenInvariant(𝐐.self)
    }
    
    public func RasmussenInvariant<F: Field>(_ type: F.Type, forceCompute: Bool = false) -> Int {
        if !forceCompute, F.self == 𝐐.self, let s = Link.loadRasmussenInvariant(self.name) {
            return s
        }
        
        assert(components.count == 1) // currently supports only knots.
        
        typealias R = Polynomial<F, t4> // R = F[t], deg(t) = -4.
        
        let L = self
        let H0 = L.KhovanovChainComplex(R.self, h: .zero, t: R.indeterminate).homology(0).freePart
        let q = H0.generators.map { z in
            z.generators.map { x in x.qDegree(in: L) }.min()!
            }.max()!
        
        return q - 1
    }
}
