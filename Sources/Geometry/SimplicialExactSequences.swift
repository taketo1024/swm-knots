//
//  SimplicialExactSequences.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/13.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public extension HomologyExactSequence where chainType == Descending, A == Simplex {
    public init(_ X: SimplicialComplex, _ A: SimplicialComplex, _ type: R.Type) {
        let CA  = ChainComplex(A, type)
        let CX  = ChainComplex(X, type)
        let CXA = ChainComplex(X, A, type)
        
        let i = ChainMap(SimplicialMap.inclusion(from: A, to: X), R.self)
        let j = ChainMap(from: CX, to: CXA) { s in
            CXA.chainBasis(s.degree).contains(s) ? SimplicialChain(s) : SimplicialChain.zero
        }
        let d = ChainMap(from: CXA, to: CA, shift: -1) { s in
            s.boundary(R.self)
        }
        
        self.init(CA, i, CX, j, CXA, d)
    }
    
    public static func MayerVietoris(_ X: SimplicialComplex, _ A: SimplicialComplex, _ B: SimplicialComplex, _ type: R.Type) -> HomologyExactSequence<A, R> {
        
        //               A
        //         iA ↗︎     ↘︎ jA
        //   A ∩ B               A ∪ B = X
        //         iB ↘︎     ↗︎ jB
        //               B
        //
        // ==>
        //                   iA⊕iB               jA-jB
        //   0  -> C(A ∩ B) ------> C(A) ⊕ C(B) ------> C(A + B) -> 0  (exact)
        //
        // ==>
        //
        //   .. -> H(A ∩ B) ------> H(A) ⊕ H(B) ------> H(A + B) ~= H(X) -> ... (exact)
        //
        
        let AnB = A ∩ B
        
        let CAnB = ChainComplex(AnB, type)
        let CA   = ChainComplex(A,   type)
        let CB   = ChainComplex(B,   type)
        let CX   = ChainComplex(X,   type)
        
        let iA = ChainMap(SimplicialMap.inclusion(from: AnB, to: A), R.self)
        let iB = ChainMap(SimplicialMap.inclusion(from: AnB, to: B), R.self)
        let jA = ChainMap(SimplicialMap.inclusion(from: A,   to: X), R.self)
        let jB = ChainMap(SimplicialMap.inclusion(from: B,   to: X), R.self)
        
        let CAB = CA ⊕ CB
        let   i = iA ⊕ iB
        let   j = jA - jB
        
        let d = ChainMap(from: CX, to: CAnB, shift: -1) { s in
            A.contains(s) ? s.boundary(type) : SimplicialChain.zero
        }
        
        fatalError()
//        return HomologyExactSequence(CAnB, i, CAB, j, CX, d)
    }
}
