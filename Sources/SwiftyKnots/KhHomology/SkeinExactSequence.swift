//
//  SkeinExactSequence.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/17.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension Link {
    public func skeinExactSequence<R>(_ type: R.Type, atCrossing i: Int? = nil, reduced: Bool = false) -> ChainComplex2SES<KhTensorElement, KhTensorElement, KhTensorElement, R> {
        
        typealias M = ChainMap2<KhTensorElement, KhTensorElement, R>
        
        let (n, n⁺, n⁻) = (crossingNumber, crossingNumber⁺, crossingNumber⁻)
        let L = (i == nil || i! == n - 1)
            ? self
            : Link(name: name, crossings: crossings.moved(elementAt: i!, to: n - 1))
        
        let (L0, L1) = L.splicedPair(at: n - 1)

        //                 i      j
        //  0 --> c1{1,1} ---> c ---> c0 --> 0 (exact)
        //
        
        let CKh  =  L.KhChainComplex(R.self, reduced: reduced)
        
        let CKh0 = L0.KhChainComplex(R.self, reduced: reduced, normalized: false)
                     .shifted(-n⁻, n⁺ - 2 * n⁻)
        let CKh1 = L1.KhChainComplex(R.self, reduced: reduced, normalized: false)
                     .shifted(-n⁻ + 1, n⁺ - 2 * n⁻ + 1)
        
        let i = M { (_, _, e) in FreeModule(e.stateModified(n, .I)) }
        let j = M { (_, _, e) in
            e.state[n] == .O ? FreeModule(e.stateModified(n, nil)) : .zero
        }
        
        let d = M(bidegree: (1, 0)) { (_, _, e0) in
            let e = e0.stateModified(n, .O)
            let de: FreeModule<KhTensorElement, R> = L.KhCube.d(e)
            return de.map { (e, a) -> (KhTensorElement, R) in
                e.state[n] == .I ? (e.stateModified(n, nil), a) : (e, .zero)
            }
        }
        
        return ChainComplex2SES(CKh1, i, CKh, j, CKh0, d)
    }
}
