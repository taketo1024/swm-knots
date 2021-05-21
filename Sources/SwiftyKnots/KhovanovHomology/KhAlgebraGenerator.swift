//
//  KhovanovAlgebraGenerator.swift
//  
//
//  Created by Taketo Sano on 2021/05/08.
//

import SwiftyMath

public enum KhovanovAlgebraGenerator: Int8, LinearCombinationGenerator, Codable {
    case I = 0
    case X = 1

    public var degree: Int {
        (self == .I) ? 0 : -2
    }
    
    public static func <(e1: Self, e2: Self) -> Bool {
        e1.degree < e2.degree
    }

    public var description: String {
        (self == .I) ? "1" : "X"
    }
}

extension IndexedModule where Index == Cube.Coords, M: LinearCombinationType, M.Generator == MultiTensorGenerator<KhovanovAlgebraGenerator> {
    public var qDegree: Int {
        elements.map { (v, z) -> Int in
            z.elements.map { (x, r) -> Int in
                v.weight + r.degree + x.degree + x.factors.count
            }.min() ?? 0
        }.min() ?? 0
    }
}
