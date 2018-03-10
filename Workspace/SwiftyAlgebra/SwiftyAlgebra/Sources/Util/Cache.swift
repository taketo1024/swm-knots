//
//  Cache.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/08/02.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public final class Cache<T> {
    public var value: T?
    public init(_ value: T? = nil) {
        self.value = value
    }
    public func clear() {
        self.value = nil
    }
    public func copy() -> Cache<T> {
        return Cache(value)
    }
}
