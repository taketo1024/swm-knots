//
//  DynamicType.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/04.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol DynamicTypeInfo: class, Equatable, CustomStringConvertible {
    associatedtype Base: SetType
    static func defaultInfo() -> Self
}

public extension DynamicTypeInfo {
    public var description: String {
        return "\(type(of: self))"
    }
    
    public static func == (_ t1: Self, _ t2: Self) -> Bool {
        return type(of: t1) == type(of: t2)
    }
}

public protocol DynamicSubtypeInfo: DynamicTypeInfo {
    func contains(_ a: Base) -> Bool
}

public protocol DynamicFiniteSubtypeInfo: DynamicSubtypeInfo {
    var allElements: Set<Base> { get }
}

public extension DynamicFiniteSubtypeInfo {
    public func contains(_ a: Base) -> Bool {
        return allElements.contains(a)
    }
}

public protocol DynamicQuotientTypeInfo: DynamicTypeInfo {
    associatedtype SubtypeInfo: DynamicSubtypeInfo
    associatedtype Base = SubtypeInfo.Base
    
//    var subtypeInfo: SubtypeInfo { get }
    func isEquivalent(_ a: Base, _ b: Base) -> Bool
    func hashValue(of a: Base) -> Int
}

public protocol DynamicType: SetType {
    associatedtype Info: DynamicTypeInfo
    
    var info: Info { get }
    static func chooseInfo(_ a: Self, _ b: Self) -> Info
}

public extension DynamicType {
    static func chooseInfo(_ a: Self, _ b: Self) -> Info {
        let def = Info.defaultInfo()
        switch (a.info, b.info) {
        case _ where a.info == b.info:
            return a.info
        case (_, def):
            return a.info
        case (def, _):
            return b.info
        default:
            fatalError("mismatching info: \(a.info), \(b.info)")
        }
    }

    public static var symbol: String {
        return "Dynamic<\(Info.Base.symbol)>"
    }
}

public protocol DynamicQuotientType: DynamicType {
    associatedtype Info: DynamicQuotientTypeInfo
    typealias Base = Info.Base
    
    var representative: Base { get }
    var info: Info { get }
    init(_ g: Base, info: Info)
}

public extension DynamicQuotientType {
    public init(_ g: Base) {
        self.init(g, info: Info.defaultInfo())
    }
    
    public static func == (_ a: Self, _ b: Self) -> Bool {
        return chooseInfo(a, b).isEquivalent(a.representative, b.representative)
    }
    
    public var hashValue: Int {
        return info.hashValue(of: representative)
    }
    
    public var description: String {
        return representative.description
    }
}
