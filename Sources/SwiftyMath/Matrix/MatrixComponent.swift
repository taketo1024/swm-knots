//
//  MatrixComponent.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/04/24.
//

import Foundation

public struct MatrixComponent<R: Ring>: Hashable {
    public let row: Int
    public let col: Int
    public let value: R
    
    public init(_ row: Int, _ col: Int, _ value: R) {
        self.row = row
        self.col = col
        self.value = value
    }
}

extension MatrixComponent: Codable where R: Codable {}
