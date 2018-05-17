//
//  debug.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/05/19.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct LogFlag {
    public let id: String
    public let label: String
    
    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }
    
    public static let warn  = LogFlag(id: "Standard.warn", label: "warn")
    public static let error = LogFlag(id: "Standard.error", label: "error")
}

private var flags = Set([LogFlag.warn.id, LogFlag.error.id])

public class Logger {
    public static func activate(_ flag: LogFlag) {
        flags.insert(flag.id)
    }
    
    public static func inactivate(_ flag: LogFlag) {
        flags.remove(flag.id)
    }
    
    public static func write(_ flag: LogFlag, _ msg: @autoclosure () -> String) {
        if flags.contains(flag.id) {
            print("[\(flag.label)] \(msg())")
        }
    }
}
