//
//  DynamicGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/05.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class IdealInfo<R: Ring>: TypeInfo {
    public typealias Base = R
    
    public func reduced(_ r: R) -> R {
        fatalError("implement in subclass")
    }
    
    public func contains(_ r: R) -> Bool {
        fatalError("implement in subclass")
    }
    
    public func inverseInQuotient(_ r: R) -> R? {
        fatalError("implement in subclass")
    }
    
    public var description: String {
        return "\(type(of: self))"
    }
}

public final class EuclideanIdealInfo<R: EuclideanRing>: IdealInfo<R> {
    public let generator: R
    
    public init(generator: R)  {
        self.generator = generator
        super.init()
    }
    
    public override func reduced(_ r: R) -> R {
        return r % generator
    }
    
    public override func contains(_ r: R) -> Bool {
        return r % generator == R.zero
    }
    
    public override func inverseInQuotient(_ r: R) -> R? {
        // same implementation as in `EuclideanIdeal`
        let (a, _, u) = bezout(r, generator)
        return u.inverse.map{ inv in inv * a }
    }
    
    public override var description: String {
        return "(\(generator))"
    }
}

public struct DynamicIdeal<R: Ring, _ID: _Int>: DynamicType, Ideal {
    public typealias Super = R
    public typealias Info = IdealInfo<R>
    public typealias ID = _ID
    
    public let r: R
    
    public init(_ r: R) {
        self.r = r
    }
    
    public var asSuper: R {
        return r
    }
    
    public static func reduced(_ r: R) -> R {
        return info.reduced(r)
    }
    
    public static func contains(_ r: R) -> Bool {
        return info.contains(r)
    }
    
    public static func inverseInQuotient(_ r: R) -> R? {
        return info.inverseInQuotient(r)
    }
    
    public static var symbol: String {
        return info.description
    }
}
