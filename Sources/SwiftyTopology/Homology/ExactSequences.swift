//
//  SimplicialExactSequences.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/12/13.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension SimplicialComplex {
    
    //             i         j
    //   0 -> CA  --->  CX  ---> CXA -> 0  (exact)
    //
    
    public static func shortExactSequence<R>(_ X: SimplicialComplex, _ A: SimplicialComplex, _ type: R.Type) -> ChainShortExactSequence<Simplex, Simplex, Simplex, R> {
        
        typealias M = ChainMap<Simplex, Simplex, R>
        
        let CA  = A.chainComplex(R.self)
        let CX  = X.chainComplex(R.self)
        let CXA = X.chainComplex(relativeTo: A, R.self)
        
        let i = SimplicialMap.inclusion(from: A, to: X).asChainMap(R.self)
        let j = M.uniform(degree:  0) { (s: Simplex) in !A.contains(s) ? .wrap(s) : .zero }
        let d = M.uniform(degree: -1) { (s: Simplex) in s.boundary(R.self) }
        
        return ChainShortExactSequence(CA, i, CX, j, CXA, d)
    }
    
    public static func homologyExactSequence<R>(_ X: SimplicialComplex, _ A: SimplicialComplex, _ type: R.Type) -> HomologyExactSequenceSolver<Simplex, Simplex, Simplex, R> {
        
        typealias H = HomologyExactSequenceSolver<Simplex, Simplex, Simplex, R>
        return H(shortExactSequence(X, A, type))
    }
    
    public static func cohomologyExactSequence<R>(_ X: SimplicialComplex, _ A: SimplicialComplex, _ type: R.Type) -> HomologyExactSequenceSolver<Dual<Simplex>, Dual<Simplex>, Dual<Simplex>, R> {
        
        typealias H = HomologyExactSequenceSolver<Dual<Simplex>, Dual<Simplex>, Dual<Simplex>, R>
        return H(shortExactSequence(X, A, type).dual)
    }
}

/*
public extension HomologyExactSequence where T == Descending, A == Simplex, B == Sum<Simplex, Simplex>, C == Simplex {
    public static func MayerVietoris(_ X: SimplicialComplex, _ A: SimplicialComplex, _ B: SimplicialComplex, _ type: R.Type) -> HomologyExactSequence<A, B, C, R> {
        
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
        
        typealias C = ChainComplex
        typealias M = ChainMap
        
        let AnB = A ∩ B
        
        let (CAnB, CA, CB, CX) = (C(AnB, R.self), C(A, R.self), C(B, R.self), C(X, R.self))
        let CAB = CA ⊕ CB
        
        let iA = M.induced(from: SimplicialMap.inclusion(from: AnB, to: A), R.self)
        let iB = M.induced(from: SimplicialMap.inclusion(from: AnB, to: B), R.self)
        let jA = M.induced(from: SimplicialMap.inclusion(from: A,   to: X), R.self)
        let jB = M.induced(from: SimplicialMap.inclusion(from: B,   to: X), R.self)
        
        let Δ = ChainMap.diagonal(from: CAnB)
        let i = (iA ⊕ iB) ∘ Δ
        let j = ChainMap { (c: Sum<Simplex, Simplex>) -> SimplicialChain<R>  in
            switch c {
            case let ._1(a): return  jA.applied(to: a)
            case let ._2(b): return -jB.applied(to: b)
            }
        }
        let d = M { (s: Simplex) in s.boundary(R.self) }
        
        return HomologyExactSequence(CAnB, i, CAB, j, CX, d)
    }
}


public extension CohomologyExactSequence where T == Ascending, A == Dual<Simplex>, B == Sum<Dual<Simplex>, Dual<Simplex>>, C == Dual<Simplex> {
    public static func MayerVietoris(_ X: SimplicialComplex, _ A: SimplicialComplex, _ B: SimplicialComplex, _ type: R.Type) -> CohomologyExactSequence<A, B, C, R> {
        
        //               A
        //         iA ↗︎     ↘︎ jA
        //   A ∩ B               A ∪ B = X
        //         iB ↘︎     ↗︎ jB
        //               B
        //
        // ==>
        //
        //                   iA* + iB*                jA* ⊕ (-jB)*
        //   0  <- C*(A ∩ B) <-------- C*(A) ⊕ C*(B) <----------- C*(A + B) <- 0  (exact)
        //
        // ==>
        //
        //   .. <- H*(A ∩ B) <-------- H*(A) ⊕ H*(B) <----------- H*(A + B) <- 0  (exact)
        //                                                        ~= H*(X)
        //
        
        typealias C = ChainComplex
        typealias M = ChainMap
        
        let AnB = A ∩ B
        
        let (CAnB, CA, CB, CX) = (C(AnB, R.self), C(A, R.self), C(B, R.self), C(X, R.self))
        let (DAnB, DA, DB, DX) = (CAnB.dual, CA.dual, CB.dual, CX.dual)
        let DAB = DA ⊕ DB
        
        let iA = M.induced(from: SimplicialMap.inclusion(from: AnB, to: A), R.self).dual(domain: CAnB)
        let iB = M.induced(from: SimplicialMap.inclusion(from: AnB, to: B), R.self).dual(domain: CAnB)
        let jA = M.induced(from: SimplicialMap.inclusion(from: A,   to: X), R.self).dual(domain: CA)
        let jB = M.induced(from: SimplicialMap.inclusion(from: B,   to: X), R.self).dual(domain: CB)
        
        let i = CochainMap { (c: Sum<Dual<Simplex>, Dual<Simplex>>) -> SimplicialCochain<R>  in
            switch c {
            case let ._1(a): return iA.applied(to: a)
            case let ._2(b): return iB.applied(to: b)
            }
        }
        
        let Δ = CochainMap.diagonal(from: DX)
        let j = (jA ⊕ (-jB)) ∘ Δ
        let d = M { (s: Simplex) in s.boundary(R.self) }.dual(domain: CX)
        
        return CohomologyExactSequence(DX, j, DAB, i, DAnB, d)
    }
}
*/
