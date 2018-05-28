//
//  SkeinExactSequence.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/17.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension SkeinTriple {
    
    //                      i           j
    //  0 --> CKh(L1){1,1} ---> CKh(L) ---> CKh(L0) --> 0 (exact)
    //
    
    public func shortExactSequence<R>(_ type: R.Type, reduced r: Bool = false) -> ChainComplex2SES<KhTensorElement, KhTensorElement, KhTensorElement, R> {
        
        let (n, n⁺, n⁻) = (L.crossingNumber, L.crossingNumber⁺, L.crossingNumber⁻)
        
        let C  =  L.KhChainComplex(R.self, reduced: r)
        let C0 = L0.KhChainComplex(R.self, reduced: r, normalized: false).shifted(-n⁻,     n⁺ - 2 * n⁻)
        let C1 = L1.KhChainComplex(R.self, reduced: r, normalized: false).shifted(-n⁻ + 1, n⁺ - 2 * n⁻ + 1)
        
        typealias M = ChainMap2<KhTensorElement, KhTensorElement, R>
        
        let i = M { (_, _, e) in FreeModule(e.stateModified(n - 1, .I)) }
        let j = M { (_, _, e) in
            e.state[n - 1] == .O ? FreeModule(e.stateModified(n - 1, nil)) : .zero
        }
        
        let d = M(bidegree: (1, 0)) { (_, _, e0) in
            let e = e0.stateModified(n, .O)
            let d = self.L.KhCube.d(R.self)
            return d.applied(to: e).map { (e, a) -> (KhTensorElement, R) in
                e.state[n] == .I ? (e.stateModified(n, nil), a) : (e, .zero)
            }
        }
        
        return ChainComplex2SES(C1, i, C, j, C0, d)
    }
}
