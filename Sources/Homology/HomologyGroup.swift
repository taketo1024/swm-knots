//
//  HomologyGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/18.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol _HomologyGroup: _QuotientModule {
    associatedtype chainType: ChainType
    associatedtype CoeffRing: EuclideanRing
    associatedtype BasisElement: FreeModuleBase
    
    var representative: FreeModule<CoeffRing, BasisElement> { get }
    init(_ z: FreeModule<CoeffRing, BasisElement>)
    
    static var degree: Int { get }
    static func generator(_ i: Int) -> Self
    static var info: HomologyGroupInfo<chainType, CoeffRing, BasisElement> { get }
}

public extension _HomologyGroup where Base == FreeModule<CoeffRing, BasisElement> {
    public static var degree: Int {
        return info.degree
    }
    
    public static func generator(_ i: Int) -> Self {
        return Self.init(info.generator(i))
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

public typealias   DynamicHomologyGroup<R: EuclideanRing, A: FreeModuleBase, ID: _Int> = _DynamicHomologyGroup<Descending, R, A, ID>
public typealias DynamicCohomologyGroup<R: EuclideanRing, A: FreeModuleBase, ID: _Int> = _DynamicHomologyGroup<Ascending,  R, A, ID>

public struct _DynamicHomologyGroup<_chainType: ChainType, R: EuclideanRing, A: FreeModuleBase, _ID: _Int>: DynamicType, _HomologyGroup {
    public typealias Base = FreeModule<R, A>
    public typealias Sub  = FreeZeroModule<R, A> // used as stub
    public typealias chainType = _chainType
    public typealias CoeffRing = R
    public typealias BasisElement = A
    public typealias Info = HomologyGroupInfo<chainType, R, A>
    public typealias ID = _ID
    
    private let z: FreeModule<R, A>
    public init(_ z: FreeModule<R, A>) {
        // TODO check if z is a cycle.
        self.z = z
    }
    
    public var representative: FreeModule<R, A> {
        return z
    }
}
