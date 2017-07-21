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
    associatedtype A: FreeModuleBase
    associatedtype R: EuclideanRing
    
    var representative: FreeModule<A, R> { get }
    init(_ z: FreeModule<A, R>)
    
    static var dim: Int { get }
    static func generator(_ i: Int) -> Self
    static var info: HomologyGroupInfo<chainType, A, R> { get }
}

public extension _HomologyGroup where Base == FreeModule<A, R> {
    public static var dim: Int {
        return info.dim
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

public extension _HomologyGroup where Base == FreeModule<A, R>, chainType == Ascending {
    public static func * <H: _HomologyGroup>(a: Self, b: H) -> R where Self.A == H.A, Self.R == H.R, H.chainType == Descending {
        assert(Self.info.dim == H.info.dim)
        let x = a.representative
        let y = b.representative
        let basis = (x.basis + y.basis).unique()
        return basis.reduce(R.zero) { (sum, e) in sum + x.component(forBasisElement: e) * y.component(forBasisElement: e) }
    }
    
    public static func * <H: _HomologyGroup>(b: H, a: Self) -> R where Self.A == H.A, Self.R == H.R, H.chainType == Descending {
        return a * b
    }
}

public typealias   DynamicHomologyGroup<A: FreeModuleBase, R: EuclideanRing, ID: _Int> = _DynamicHomologyGroup<Descending, A, R, ID>
public typealias DynamicCohomologyGroup<A: FreeModuleBase, R: EuclideanRing, ID: _Int> = _DynamicHomologyGroup<Ascending,  A, R, ID>

public struct _DynamicHomologyGroup<_chainType: ChainType, _A: FreeModuleBase, _R: EuclideanRing, _ID: _Int>: DynamicType, _HomologyGroup {
    public typealias chainType = _chainType
    public typealias A = _A
    public typealias R = _R
    public typealias Base = FreeModule<A, R>
    public typealias Sub  = FreeZeroModule<A, R> // used as stub
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
