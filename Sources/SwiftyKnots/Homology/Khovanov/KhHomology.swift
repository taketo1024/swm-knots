//
//  KhHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath
import SwiftyHomology

extension Homology where GridDim == _2 {
    // Σ_{i, j} (-1)^i q^j rank(H[i, j])
    public var gradedEulerCharacteristic: LaurentPolynomial<_q, 𝐙> {
        typealias P = LaurentPolynomial<_q, 𝐙>
        let q = P.indeterminate
        return grid.supportedCoords.sum{ c in
            let (i, j) = (c[0], c[1])
            return P((-1).pow(i) * self[i, j].rank) * q.pow(j)
        }
    }
}

extension Link {
    public func KhovanovHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> Homology2<FreeModule<KhEnhancedState, R>> {
        let L = self
        let (n⁺, n⁻) = (L.crossingNumber⁺, L.crossingNumber⁻)
        
        let cube = KhCube<R>(link: L)
        let chainCpx = cube.fold()
        
        let (qmin, qmax) = (cube.startVertex.generators.map{ $0.degree }.min()!,
                            cube.endVertex  .generators.map{ $0.degree }.max()!)
        let support = (0 ... cube.dim).flatMap{ i in (0 ... (qmax - qmin) / 2).map{ j in [i, qmin + 2 * j] } }
        
        let bigraded = ChainComplex2(grid: ModuleGrid(supportedCoords: support) { I in
            let (i, j) = (I[0], I[1])
            let Ci = chainCpx[i]
            let gens = Ci.generators.compactMap{ e -> KhEnhancedState? in
                let x = e.decomposed()[0].0
                return (x.degree == j) ? x : nil
            }
            return ModuleObject(basis: gens)
            }, differential: ChainMap2(multiDegree: [1, 0]) { I in
                chainCpx.differential[I[0]]
        }).shifted(normalized ? [-n⁻, n⁺ - 2 * n⁻] : [0, 0])
        
        return bigraded.homology
    }
    
    public func parameterizedKhovanovHomology<R: EuclideanRing>(_ type: R.Type, h: R, t: R, normalized: Bool = true) -> Homology1<FreeModule<KhEnhancedState, R>> {
        let n⁻ = crossingNumber⁻
        let cube = KhCube<R>(link: self, h: h, t: t)
        let chainComplex = cube.fold().shifted(normalized ? -n⁻ : 0)
        return chainComplex.homology
    }
    
    public func LeeHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> Homology1<FreeModule<KhEnhancedState, R>> {
        return parameterizedKhovanovHomology(R.self, h: .zero, t: .identity, normalized: normalized)
    }

    public func BarNatanHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> Homology1<FreeModule<KhEnhancedState, R>> {
        return parameterizedKhovanovHomology(R.self, h: .identity, t: .zero, normalized: normalized)
    }
}
