//
//  ChainComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/04.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct SimplicialChainComplex<R: Ring>: CustomStringConvertible {
    public typealias M = FreeModule<Simplex, R>
    public typealias F = FreeModuleHom<Simplex, R>
    
    public let chainBases: [[Simplex]] // [[0-chain], [1-chain], ..., [n-chain]]
    public let boundaryMaps: [F] // [(d_0 = 0), (d_1 = C_1 -> C_0), ..., (d_n: C_n -> C_{n-1}), (d_{n+1} = 0)]
    
    public init(simplices: [Simplex]) {
        func sgn(_ i: Int) -> Int {
            return (i % 2 == 0) ? 1 : -1
        }
        
        let dim = simplices.reduce(0){ max($0, $1.dim) }
        
        var chns: [[Simplex]] = (0 ... dim).map{_ in []}
        for s in simplices {
            chns[s.dim].append(s)
        }
        
        var bnds: [F] = [F.zero]
        bnds += (1 ... dim).map { (i) -> F in
            let from = chns[i]
            let map = Dictionary.generateBy(keys: from){ (s) -> M in
                return s.faces().enumerated().reduce(M.zero){ (res, el) -> M in
                    let (i, t) = el
                    return res + R(sgn(i)) * M(t)
                }
            }
            return F(map)
        }
        bnds += [F.zero]
        
        self.chainBases = chns
        self.boundaryMaps = bnds
    }
    
    public func boundaryMap(_ i: Int) -> FreeModuleHom<Simplex, R> {
        return boundaryMaps[i]
    }
    
    public var description: String {
        return chainBases.description
    }
}
