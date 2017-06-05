//
//  DynamicGroup.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/05.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class DynamicSubgroupInfo<G: Group>: DynamicSubtypeInfo {
    public typealias Base = G
    
    public func contains(_ g: G) -> Bool {
        fatalError("implement in subclass")
    }
    
    public static func defaultInfo() -> Self {
        fatalError("implement in subclass")
    }
}

public final class DynamicFiniteSubgroupInfo<G: Group>: DynamicSubgroupInfo<G> {
    public let allElements: Set<G>
    
    public init<S: Sequence>(allElements: S) where S.Iterator.Element == G {
        self.allElements = Set(allElements)
        super.init()
    }
    
    public var countElements: Int {
        return allElements.count
    }
    
    public override func contains(_ g: G) -> Bool {
        return allElements.contains(g)
    }
    
    public var description: String {
        return "{\(Array(allElements).map{"\($0)"}.joined(separator: ", "))}"
    }
}

public final class DynamicQuotientGroupInfo<G: Group>: DynamicQuotientTypeInfo {
    public typealias Base = G
    public typealias SubtypeInfo = DynamicSubgroupInfo<G>
    
    public let subtypeInfo: DynamicSubgroupInfo<G>?
    
    public init(subtypeInfo: SubtypeInfo?) {
        self.subtypeInfo = subtypeInfo
    }
    
    public func image(of g: Base) -> DynamicQuotientGroup<G> {
        return DynamicQuotientGroup(g, info: self)
    }
    
    public func isEquivalent(_ a: G, _ b: G) -> Bool {
        return subtypeInfo?.contains(a * b.inverse) ?? (a == b)
    }
    
    public func hashValue(of a: G) -> Int {
        return 0 // TODO
    }
    
    public static func defaultInfo() -> DynamicQuotientGroupInfo<G> {
        return DynamicQuotientGroupInfo<G>(subtypeInfo: nil) 
    }
}

public struct DynamicQuotientGroup<G: Group>: Group, DynamicQuotientType {

    public typealias Info = DynamicQuotientGroupInfo<G>
    
    private let g: G
    public let info: Info
    
    public init(_ g: G, info: Info) {
        self.g = g
        self.info = info
    }
    
    public var representative: G {
        return g
    }
    
    public static var identity: DynamicQuotientGroup<G> {
        return DynamicQuotientGroup(G.identity, info: Info.defaultInfo())
    }
    
    public var inverse: DynamicQuotientGroup<G> {
        return DynamicQuotientGroup(representative.inverse, info: info)
    }
    
    public static func * (_ a: DynamicQuotientGroup<G>, _ b: DynamicQuotientGroup<G>) -> DynamicQuotientGroup<G> {
        return DynamicQuotientGroup(a.representative * b.representative, info: chooseInfo(a, b))
    }
}

public extension Group {
    public static func quotient(by subgroup: DynamicSubgroupInfo<Self>) -> DynamicQuotientGroupInfo<Self> {
        return DynamicQuotientGroupInfo(subtypeInfo: subgroup)
    }
    
    public func asQuotient(_ quotient: DynamicQuotientGroupInfo<Self>) -> DynamicQuotientGroup<Self> {
        return DynamicQuotientGroup(self, info: quotient)
    }
}
