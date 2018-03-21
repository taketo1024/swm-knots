//
//  HomologyMap.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/12.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias   HomologyMap<A: FreeModuleBase, B: FreeModuleBase, R: EuclideanRing> = _HomologyMap<Descending, A, B, R>
public typealias CohomologyMap<A: FreeModuleBase, B: FreeModuleBase, R: EuclideanRing> = _HomologyMap<Ascending,  A, B, R>

public struct _HomologyMap<T: ChainType, A: FreeModuleBase, B: FreeModuleBase, R: EuclideanRing>: _ModuleHom {
    public typealias CoeffRing = R
    public typealias Domain   = _HomologyClass<T, A, R>
    public typealias Codomain = _HomologyClass<T, B, R>
    
    private let f: (Domain) -> Codomain
    
    public init(from: _Homology<T, A, R>, to: _Homology<T, B, R>, inducedFrom chainMap: _ChainMap<T, A, B, R>) {
        self.init { x in
            _HomologyClass(chainMap.applied(to: x.representative), to)
        }
    }
    
    public init(_ f: @escaping (_HomologyClass<T, A, R>) -> _HomologyClass<T, B, R>) {
        self.f = f
    }
    
    public func applied(to x: _HomologyClass<T, A, R>) -> _HomologyClass<T, B, R> {
        return f(x)
    }
}

