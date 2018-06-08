//
//  Cache.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/08/02.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public final class Cache<T>: CustomStringConvertible {
    public var value: T?
    
    public init(_ value: T? = nil) {
        self.value = value
    }
    
    public static var empty: Cache<T> {
        return Cache()
    }
    
    public var hasValue: Bool {
        return value != nil
    }
    
    public func useCacheOrSet(_ initializer: @autoclosure () -> T) -> T {
        return useCacheOrSet(initializer)
    }
    
    public func useCacheOrSet(_ initializer: () -> T) -> T {
        if let v = value {
            return v
        }
        
        let v = initializer()
        value = v
        return v
    }
    
    public func clear() {
        self.value = nil
    }
    
    public func copy() -> Cache<T> {
        return Cache(value)
    }
    
    public var description: String {
        return value == nil ? "empty" : "cache(\(value!))"
    }
}
