//
//  DynamicType.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/06/04.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol TypeInfo: class, CustomStringConvertible {
}

public protocol DynamicType {
    associatedtype Info: TypeInfo
    associatedtype ID: _Int
    
    static func register(_ info: Info)
    static var info: Info { get }
}

private var DynamicTypeRegisteredInfos: Dictionary<String, Any> = [:]

public extension DynamicType {
    private static var registerID: String {
        return "\(Self.self).\(ID.intValue)"
    }
    
    public static func register(_ info: Info) {
        DynamicTypeRegisteredInfos[registerID] = info
    }
    
    public static var info: Info {
        if let info = DynamicTypeRegisteredInfos[registerID] as? Info {
            return info
        } else {
            fatalError("No SubgroupInfo registered for \(Self.self), ID: \(ID.intValue)")
        }
    }
}
