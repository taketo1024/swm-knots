//
//  FreeModuleBase.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/12/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol FreeModuleBase: SetType {
    var degree: Int { get }
}

public extension FreeModuleBase {
    public var degree: Int { return 1 }
}

// Default Bases
extension Int:    FreeModuleBase { }
extension String: FreeModuleBase { }

// Derived Bases
public struct Dual<A: FreeModuleBase>: FreeModuleBase {
    public let base: A
    public init(_ a: A) {
        base = a
    }
    
    public var degree: Int {
        return base.degree
    }
    
    public var hashValue: Int {
        return base.hashValue
    }
    
    public func pair(_ s: A) -> Int {
        return (base == s) ? 1 : 0
    }
    
    public static func ==(a: Dual<A>, b: Dual<A>) -> Bool {
        return a.base == b.base
    }
    
    public var description: String {
        return "\(base)*"
    }
}
