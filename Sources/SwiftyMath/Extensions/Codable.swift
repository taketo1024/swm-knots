//
//  Codable.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/04/25.
//

import Foundation

public extension Encodable {
    public func asJSON(prettyPrint: Bool = false) -> String {
        let e = JSONEncoder()
        if prettyPrint {
            e.outputFormatting = .prettyPrinted
        }
        if let data = try? e.encode(self), let str = String(bytes: data, encoding: .utf8) {
            return str
        } else {
            return ""
        }
    }
}
