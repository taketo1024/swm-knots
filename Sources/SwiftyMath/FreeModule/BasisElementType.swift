//
//  BasisElementType.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/12/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol BasisElementType: SetType {
    var degree: Int { get }
}

public extension BasisElementType {
    public var degree: Int { return 1 }
}

// Default Bases
extension Int:    BasisElementType { }
extension String: BasisElementType { }

// Derived Bases
public struct Dual<A: BasisElementType>: BasisElementType {
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
