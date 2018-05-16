//
//  KhovanovHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension Link {
    public var KhCube: SwiftyKnots.KhCube {
        return SwiftyKnots.KhCube(self)
    }
    
    public func KhChainComplex<R: EuclideanRing>(_ type: R.Type, unnormalized: Bool = false, reduced: Bool = false) -> CochainComplex<KhTensorElement, R> {
        return KhChainComplex(KhCube, KhBasisElement.μ, KhBasisElement.Δ, R.self, unnormalized: unnormalized, reduced: reduced)
    }

    public func KhChainComplex<R: EuclideanRing>(_ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>, _ type: R.Type, unnormalized: Bool = false, reduced: Bool = false) -> CochainComplex<KhTensorElement, R> {
        return KhChainComplex(KhCube, μ, Δ, R.self, unnormalized: unnormalized, reduced: reduced)
    }
    
    internal func KhChainComplex<R: EuclideanRing>(_ cube: KhCube, _ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>, _ type: R.Type, unnormalized: Bool, reduced: Bool) -> CochainComplex<KhTensorElement, R> {
        typealias C = CochainComplex<KhTensorElement, R>
        
        let (n, n⁺, n⁻) = (crossingNumber, crossingNumber⁺, crossingNumber⁻)
        
        let name = "CKh(\(self.name); \(R.symbol))"
        let chain = (0 ... n).map { i -> (C.ChainBasis, C.BoundaryMap) in
            let chainBasis = (!reduced ? cube.basis(degree: i) : cube.reducedBasis(degree: i))
            let boundaryMap = C.BoundaryMap { (x: KhTensorElement) in cube.map(x, μ, Δ) }
            return (!unnormalized ? chainBasis.map{ $0.shifted(n⁺ - 2 * n⁻)} : chainBasis, boundaryMap)
        }
        
        return CochainComplex(name: name, chain: chain, offset: !unnormalized ? -n⁻ : 0)
    }
}
