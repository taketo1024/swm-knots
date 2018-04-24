//
//  MatrixComponent.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/04/24.
//

import Foundation

public struct MatrixComponent<R: Ring> {
    public let row: Int
    public let col: Int
    public let value: R
    
    public init(_ row: Int, _ col: Int, _ value: R) {
        self.row = row
        self.col = col
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey {
        case row
        case col
        case value
    }
}

extension MatrixComponent: Codable where R: Codable {
    public init(from decoder: Decoder) throws {
        fatalError()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(row, forKey: .row)
        try container.encode(col, forKey: .col)
        try container.encode(value, forKey: .value)
    }
}
