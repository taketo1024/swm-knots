//
//  DynamicGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/05.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class SubgroupInfo<G: Group>: TypeInfo {
    public typealias Base = G
    
    public func contains(_ g: G) -> Bool {
        fatalError("implement in subclass")
    }
    
    public var description: String {
        return "\(type(of: self))"
    }
}

public final class FiniteSubgroupInfo<G: Group>: SubgroupInfo<G> {
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

public struct DynamicSubgroup<G: Group, _ID: _Int>: DynamicType, Subgroup {
    public typealias Super = G
    public typealias Info = SubgroupInfo<G>
    public typealias ID = _ID
    
    public let g: G
    
    public init(_ g: G) {
        self.g = g
    }
    
    public var asSuper: G {
        return g
    }
    
    public static func contains(_ g: G) -> Bool {
        return info.contains(g)
    }
    
    public static var symbol: String {
        return info.description
    }
}
