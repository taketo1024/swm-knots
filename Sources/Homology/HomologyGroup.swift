//
//  HomologyGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/18.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

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

public typealias   DynamicHomologyGroup<A: FreeModuleBase, R: EuclideanRing, ID: _Int> = _DynamicHomologyGroup<Descending, A, R, ID>
public typealias DynamicCohomologyGroup<A: FreeModuleBase, R: EuclideanRing, ID: _Int> = _DynamicHomologyGroup<Ascending,  A, R, ID>

public struct _DynamicHomologyGroup<_chainType: ChainType, A: FreeModuleBase, R: EuclideanRing, _ID: _Int>: DynamicType, _HomologyGroup {
    public typealias Base = FreeModule<A, R>
    public typealias Sub  = FreeZeroModule<A, R> // used as stub
    public typealias chainType = _chainType
    public typealias CoeffRing = R
    public typealias BasisElement = A
    public typealias Info = HomologyGroupInfo<chainType, A, R>
    public typealias ID = _ID
    
    private let z: FreeModule<A, R>
    public init(_ z: FreeModule<A, R>) {
        // TODO check if z is a cycle.
        self.z = z
    }
    
    public var representative: FreeModule<A, R> {
        return z
    }
}
