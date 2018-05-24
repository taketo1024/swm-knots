//
//  GroupStructure.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/12/12.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct FiniteSubgroupStructure<G: Group>: SubgroupStructure {
    public typealias Base = G
    public let allElements: Set<G>
    
    public init<S: Sequence>(allElements: S) where S.Element == G {
        self.allElements = Set(allElements)
    }
    
    public var countElements: Int {
        return allElements.count
    }
    
    public func contains(_ g: G) -> Bool {
        return allElements.contains(g)
    }
    
    public static func ==(a: FiniteSubgroupStructure<G>, b: FiniteSubgroupStructure<G>) -> Bool {
        return a.allElements == b.allElements
    }
    
    public var description: String {
        return "{\(Array(allElements).map{"\($0)"}.joined(separator: ", "))}"
    }
}
