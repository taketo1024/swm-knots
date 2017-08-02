//
//  ChainMap.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/08/01.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias   ChainMap<R: Ring, A: FreeModuleBase, B: FreeModuleBase> = _ChainMap<Descending, R, A, B>
public typealias CochainMap<R: Ring, A: FreeModuleBase, B: FreeModuleBase> = _ChainMap<Ascending,  R, A, B>

public struct _ChainMap<chainType: ChainType, R: Ring, A: FreeModuleBase, B: FreeModuleBase>: Map {
    public typealias Domain   = [FreeModule<R, A>]
    public typealias Codomain = [FreeModule<R, B>]
    
    private let maps: [FreeModuleHom<R, A, B>]
    
    public let offset: Int
    public let shift: Int
    
    public init(_ maps: [FreeModuleHom<R, A, B>], offset: Int = 0, shift: Int = 0) {
        self.maps = maps
        self.offset = offset
        self.shift = shift
    }
    
    public init(from: _ChainComplex<chainType, R, A>, to: _ChainComplex<chainType, R, B>, shift: Int = 0, mapping f: (Int, A) -> [(R, B)]) {
        let maps = (from.offset ... from.topDegree).map { i -> FreeModuleHom<R, A, B> in
            FreeModuleHom(domainBasis: from.chainBasis(i), codomainBasis: to.chainBasis(i + shift), mapping: { f(i, $0) })
        }
        self.init(maps, offset: from.offset, shift: shift)
    }
    
    public var descending: Bool {
        return (chainType.self == Descending.self)
    }
    
    public var topDegree: Int {
        return maps.count - offset - 1
    }
    
    public func appliedTo(_ x: [FreeModule<R, A>]) -> [FreeModule<R, B>] {
        fatalError()
    }
    
    public func map(atIndex i: Int) -> FreeModuleHom<R, A, B> {
        return (offset ... topDegree).contains(i) ? maps[i - offset] : FreeModuleHom.zero
    }
    
    @discardableResult
    public func assertChainMap(from: _ChainComplex<chainType, R, A>, to: _ChainComplex<chainType, R, B>, debug: Bool = false) -> Bool {
        return (min(from.offset, to.offset) ... max(from.topDegree, to.topDegree)).forAll { i1 -> Bool in
            let i2 = descending ? i1 - 1 : i1 + 1
            
            //        f1
            //  C_i1 ----> C'_i1
            //    |          |
            //  d1|    c     |d2
            //    v          v
            //  C_i2 ----> C'_i2
            //        f2
            
            let (f1, f2) = (map(atIndex: i1), map(atIndex: i2))
            let (d1, d2) = (from.boundaryMap(i1), to.boundaryMap(i1 + shift))
            
            if debug {
                print("----------")
                print("C\(i1) -> C'\(i2 + shift)")
                print("----------")
                print("C\(i1) : \(d1.domainBasis)\n")
                print("f2 ∘ d1\n", (f2 ∘ d1).matrix.debugDescription, "\n")
                print("d2 ∘ f1\n", (d2 ∘ f1).matrix.debugDescription, "\n")
                print()
            }
            
            return true // f2 ∘ d1 == d2 ∘ f1
        }
    }
}
