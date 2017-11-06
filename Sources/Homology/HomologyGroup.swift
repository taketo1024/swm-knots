//
//  HomologyGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/18.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

/*
public protocol _HomologyGroup: _QuotientModule where CoeffRing: EuclideanRing {
    associatedtype chainType: ChainType
    associatedtype BasisElement: FreeModuleBase
    
    var representative: FreeModule<BasisElement, CoeffRing> { get }
    init(_ z: FreeModule<BasisElement, CoeffRing>)
    
    static var degree: Int { get }
    static func generator(_ i: Int) -> Self
    static var info: HomologyGroupInfo<chainType, BasisElement, CoeffRing> { get }
}

public extension _HomologyGroup where Base == FreeModule<BasisElement, CoeffRing> {
    public static var degree: Int {
        return info.degree
    }
    
    public static func generator(_ i: Int) -> Self {
        return Self.init(info.summands[i].generator)
    }
    
    public static func isEquivalent (a: Base, b: Base) -> Bool {
        return info.isHomologue(a, b)
    }
    
    public var hashValue: Int {
        return (Self.info.isNullHomologue(representative)) ? 0 : 1
    }
    
    public static var symbol: String {
        return info.description
    }
}

public extension _HomologyGroup where Base == FreeModule<CoeffRing, BasisElement>, chainType == Descending {
    public func evaluate<CH: _HomologyGroup>(_ f: CH) -> CoeffRing where CH.chainType == Ascending, CH.BasisElement == Dual<BasisElement>, CH.CoeffRing == CoeffRing {
        return self.representative.evaluate(f.representative)
    }
}
*/
