//
//  debug.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/19.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public func measure<T>(_ f: (Void) -> T) -> T {
    return measure("", f)
}

public func measure<T>(_ label: String, _ f: (Void) -> T) -> T {
    let date = Date()
    defer {
        let intv = -date.timeIntervalSinceNow
        print(label, "\(intv) sec.")
    }
    return f()
}
