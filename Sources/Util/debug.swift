//
//  debug.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/19.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

private let precision = 1000.0

public func measure<T>(_ f: () -> T) -> T {
    return measure("", f)
}

public func measure<T>(_ label: String, _ f: () -> T) -> T {
    let date = Date()
    defer {
        let intv = -date.timeIntervalSinceNow
        if intv < 1 {
            print(label, ":\t\(round(intv * precision * 1000) / precision) msec.")
        } else {
            print(label, ":\t\(round(intv * precision) / precision) sec.")
        }
    }
    return f()
}

func debugLog(print b: Bool = false, _ msg: @autoclosure () -> String) {
    if b { print(msg()) }
}
