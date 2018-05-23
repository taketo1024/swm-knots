//
//  KhovanovHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath
import SwiftyHomology

/*
public extension Link {
    public func KhChainComplex<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true, shifted: (Int, Int) = (0, 0)) -> CochainComplex<KhTensorElement, R> {
        return KhChainComplex(KhBasisElement.μ, KhBasisElement.Δ, R.self,
                              reduced: reduced, normalized: normalized, shifted: shifted)
    }

    public func KhChainComplex<R: EuclideanRing>(_ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>, _ type: R.Type, reduced: Bool = false, normalized: Bool = true, shifted: (Int, Int) = (0, 0)) -> CochainComplex<KhTensorElement, R> {
        typealias C = CochainComplex<KhTensorElement, R>
        
        let (n, n⁺, n⁻) = (crossingNumber, crossingNumber⁺, crossingNumber⁻)
        
        let name = "CKh(\(self.name); \(R.symbol))"
        let chain = (0 ... n).map { i -> (C.ChainBasis, C.BoundaryMap) in
            let cube = self.KhCube
            let chainBasis = { () -> C.ChainBasis in
                let basis = !reduced ? cube.basis(degree: i) : cube.reducedBasis(degree: i)
                let shift = (normalized ? n⁺ - 2 * n⁻ : 0) + shifted.1
                return (shift != 0) ? basis.map{ $0.shifted(shift) } : basis
            }()
            let boundaryMap = C.BoundaryMap { (x: KhTensorElement) in cube.map(x, μ, Δ) }
            return (chainBasis, boundaryMap)
        }
        let offset = (normalized ? -n⁻ : 0) + shifted.0
        
        return CochainComplex(name: name, chain: chain, offset: offset)
    }
}
*/
