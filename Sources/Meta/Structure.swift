//
//  DynamicType.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/04.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol Structure: class, CustomStringConvertible { }

public extension Structure {
    public var detailDescription: String {
        return description
    }
}

public class SubgroupStructure<G: Group>: Structure {
    public typealias Base = G
    
    public func contains(_ g: G) -> Bool {
        fatalError("implement in subclass")
    }
    
    public var description: String {
        return "\(type(of: self))"
    }
}

public final class FiniteSubgroupStructure<G: Group>: SubgroupStructure<G> {
    public let allElements: Set<G>
    
    public init<S: Sequence>(allElements: S) where S.Element == G {
        self.allElements = Set(allElements)
        super.init()
    }
    
    public var countElements: Int {
        return allElements.count
    }
    
    public override func contains(_ g: G) -> Bool {
        return allElements.contains(g)
    }
    
    public override var description: String {
        return "{\(Array(allElements).map{"\($0)"}.joined(separator: ", "))}"
    }
}

public class IdealStructure<R: Ring>: Structure {
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

public final class EuclideanIdealStructure<R: EuclideanRing>: IdealStructure<R> {
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
