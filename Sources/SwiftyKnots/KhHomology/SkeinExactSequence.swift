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
    
    public func shortExactSequence<R>(_ type: R.Type, reduced r: Bool = false) -> ChainShortExactSequence2<KhBasisElement, KhBasisElement, KhBasisElement, R> {
        
        let (n, n⁺, n⁻) = (L.crossingNumber, L.crossingNumber⁺, L.crossingNumber⁻)
        
        let C  =  L.KhChainComplex(R.self, reduced: r)
        let C0 = L0.KhChainComplex(R.self, reduced: r, normalized: false).shifted(-n⁻,     n⁺ - 2 * n⁻)
        let C1 = L1.KhChainComplex(R.self, reduced: r, normalized: false).shifted(-n⁻ + 1, n⁺ - 2 * n⁻ + 1)
        
        typealias M = ChainMap2<KhBasisElement, KhBasisElement, R>
        
        let i = M { (_, _, e) in
            let s = e.state.append(1)
            return FreeModule( e.toState(s) )
        }
        
        let j = M { (_, _, e) in
            if e.state[n - 1] == 0 {
                let s = e.state.dropLast()
                return FreeModule( e.toState(s) )
            } else {
                return .zero
            }
        }
        
        let d = M(bidegree: (1, 0)) { (i, j, e0) in
            let s = e0.state.append(0)
            let e = e0.toState(s)
            
            let d = C.d[i, j]
            return d.applied(to: e).map { (e, a) -> (KhBasisElement, R) in
                if e.state[n] == 1 {
                    let s = e.state.dropLast()
                    return (e.toState(s), a)
                } else {
                    return (e, .zero)
                }
            }
        }
        
        return ChainShortExactSequence2(C1, i, C, j, C0, d)
    }
}

fileprivate extension KhBasisElement {
    func toState(_ state: IntList) -> KhBasisElement {
        return KhBasisElement(state: state, factors: factors)
    }
}
