//
//  SimplicialExactSequences.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/13.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyAlgebra

public extension HomologyExactSequence where T == Descending, A == Simplex, B == Simplex, C == Simplex {
    public static func pair(_ X: SimplicialComplex, _ A: SimplicialComplex, _ type: R.Type) -> HomologyExactSequence<A, B, C, R> {
        
        //             i         j
        //   0 -> CA  --->  CX  ---> CXA -> 0  (exact)
        //
        
        typealias C = ChainComplex<Simplex, R>
        typealias M = ChainMap<Simplex, Simplex, R>
        
        let (CA, CX, CXA) = (C(A), C(X), C(X, A))
        
        let i = M.induced(from: SimplicialMap.inclusion(from: A, to: X))
        let j = M.induced(from: SimplicialMap.inclusion(from: X, to: X))
        let d = M { (s: Simplex) in s.boundary(R.self) }
        
        return HomologyExactSequence(CA, i, CX, j, CXA, d)
    }
}

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
        
        typealias C = ChainComplex<Simplex, R>
        typealias M = ChainMap<Simplex, Simplex, R>
        
        let AnB = A ∩ B
        
        let (CAnB, CA, CB, CX) = (C(AnB), C(A), C(B), C(X))
        
        let iA = M.induced(from: SimplicialMap.inclusion(from: AnB, to: A))
        let iB = M.induced(from: SimplicialMap.inclusion(from: AnB, to: B))
        let jA = M.induced(from: SimplicialMap.inclusion(from: A,   to: X))
        let jB = M.induced(from: SimplicialMap.inclusion(from: B,   to: X))
        
        let Δ = ChainMap<Simplex, Sum<Simplex, Simplex>, R>.diagonal
        let i = (iA ⊕ iB) ∘ Δ
        let j = ChainMap<Sum<Simplex, Simplex>, Simplex, R> { (c: Sum<Simplex, Simplex>) -> SimplicialChain<R>  in
            switch c {
            case let ._1(a): return  jA.applied(to: a)
            case let ._2(b): return -jB.applied(to: b)
            }
        }
        let d = M { (s: Simplex) in s.boundary(R.self) }
        
        return HomologyExactSequence(CAnB, i, CA ⊕ CB, j, CX, d)
    }
}

public extension CohomologyExactSequence where T == Ascending, A == Dual<Simplex>, B == Dual<Simplex>, C == Dual<Simplex> {
    public static func pair(_ X: SimplicialComplex, _ A: SimplicialComplex, _ type: R.Type) -> CohomologyExactSequence<A, B, C, R> {
        
        //             i         j
        //   0 -> CA  --->  CX  ---> CXA -> 0  (exact)
        //
        //
        // ==> Hom(-, R)
        //
        //             i*        j*
        //   0 <- C*A <--  C*X  <-- C*XA <- 0  (exact)
        
        typealias C = ChainComplex<Simplex, R>
        typealias M = ChainMap<Simplex, Simplex, R>

        let (CA, CX, CXA) = (C(A), C(X), C(X, A))
        
        let i = M.induced(from: SimplicialMap.inclusion(from: A, to: X)).dual(domain: CA)
        let j = M.induced(from: SimplicialMap.inclusion(from: X, to: X)).dual(domain: CX)
        let d = M { (s: Simplex) in s.boundary(R.self) }.dual(domain: CXA)
        
        return CohomologyExactSequence(CXA.dual, j, CX.dual, i, CA.dual, d)
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
        
        typealias C = ChainComplex<Simplex, R>
        typealias M = ChainMap<Simplex, Simplex, R>
        
        let AnB = A ∩ B
        
        let (CAnB, CA, CB, CX) = (C(AnB), C(A), C(B), C(X))
        
        let iA = M.induced(from: SimplicialMap.inclusion(from: AnB, to: A)).dual(domain: CAnB)
        let iB = M.induced(from: SimplicialMap.inclusion(from: AnB, to: B)).dual(domain: CAnB)
        let jA = M.induced(from: SimplicialMap.inclusion(from: A,   to: X)).dual(domain: CA)
        let jB = M.induced(from: SimplicialMap.inclusion(from: B,   to: X)).dual(domain: CB)
        
        let i = CochainMap<Sum<Dual<Simplex>, Dual<Simplex>>, Dual<Simplex>, R> { (c: Sum<Dual<Simplex>, Dual<Simplex>>) -> SimplicialCochain<R>  in
            switch c {
            case let ._1(a): return iA.applied(to: a)
            case let ._2(b): return iB.applied(to: b)
            }
        }
        
        let Δ = CochainMap<Dual<Simplex>, Sum<Dual<Simplex>, Dual<Simplex>>, R>.diagonal
        let j = (jA ⊕ (-jB)) ∘ Δ
        let d = M { (s: Simplex) in s.boundary(R.self) }.dual(domain: CX)
        
        return CohomologyExactSequence(CX.dual, j, CA.dual ⊕ CB.dual, i, CAnB.dual, d)
    }
}

