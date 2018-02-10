//
//  SimplicialChainOperations.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/02/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias SimplicialChain<R: Ring>   = FreeModule<Simplex, R>
public typealias SimplicialCochain<R: Ring> = FreeModule<Dual<Simplex>, R>

public extension SimplicialChain where A == Simplex {
    public func boundary() -> SimplicialChain<R> {
        return self.reduce(SimplicialChain<R>.zero) { (res, next) -> SimplicialChain<R> in
            let (s, r) = next
            return res + r * s.boundary(R.self)
        }
    }
}

public extension SimplicialCochain where A == Dual<Simplex> {
    public func cup(_ f: SimplicialCochain<R>) -> SimplicialCochain<R> {
        typealias D = Dual<Simplex>
        
        func cup(_ d1: D, _ d2: D) -> (D, R)? {
            let (s1, s2) = (d1.base, d2.base)
            
            if s1.sortedVertices.last! == s2.sortedVertices.first! {
                // MEMO: this simplex may not be a member of the simplicial complex.
                let s = Simplex(s1.unorderedVertices.union(s2.unorderedVertices))
                
                let (n1, n2) = (s1.dim, s2.dim)
                let e = R(intValue: (-1).pow(n1 * n2))
                return (Dual(s), e * self[d1] * f[d2])
            } else {
                return nil
            }
        }
        
        let pairs = self.basis.allCombinations(with: f.basis)
        let elements = pairs.flatMap{ (d1, d2) in cup(d1, d2) }
        
        return SimplicialCochain<R>(elements)
    }
    
    public func cap(_ z: SimplicialChain<R>) -> SimplicialChain<R> {
        typealias C = SimplicialChain<R>
        
        func cap(_ f: Dual<Simplex>, _ s: Simplex) -> (Simplex, R)? {
            let (i, j) = (s.dim, f.base.dim)
            assert(i >= j)
            
            let (s1, s2) = (Simplex(s.sortedVertices[0 ... j]), Simplex(s.sortedVertices[j ... i]))
            if s1 == f.base {
                let e = R(intValue: (-1).pow(s1.dim * s2.dim))
                return (s2, e)
            } else {
                return nil
            }
        }
        
        return z.sum { (s, r1) -> C in
            let eval = self.sum { (f, r2) -> C in
                if let (s2, e) = cap(f, s) {
                    return C([(s2, e * r2)])
                } else {
                    return C.zero
                }
            }
            return r1 * eval
        }
    }
    
    public static func ∪<R>(a: SimplicialCochain<R>, b: SimplicialCochain<R>) -> SimplicialCochain<R> {
        return a.cup(b)
    }
    
    public static func ∩<R>(a: SimplicialCochain<R>, b: SimplicialChain<R>) -> SimplicialChain<R> {
        return a.cap(b)
    }
}
