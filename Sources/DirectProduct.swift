//
//  DirectProduct.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/29.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct DirectProduct<G1: Group, G2: Group>: Group {
    public let _1: G1
    public let _2: G2
    
    public init(_ g1: G1, _ g2: G2) {
        self._1 = g1
        self._2 = g2
    }
    
    public var inverse: DirectProduct<G1, G2> {
        return DirectProduct<G1, G2>(_1.inverse, _2.inverse)
    }
    
    public static var identity: DirectProduct<G1, G2> {
        return DirectProduct<G1, G2>(G1.identity, G2.identity)
    }
    
    public static var symbol: String {
        return "\(G1.symbol)×\(G2.symbol)"
    }
}

public func == <G1: Group, G2: Group> (a: DirectProduct<G1, G2>, b: DirectProduct<G1, G2>) -> Bool {
    return (a._1 == b._1) && (a._2 == b._2)
}

public func * <G1: Group, G2: Group> (a: DirectProduct<G1, G2>, b: DirectProduct<G1, G2>) -> DirectProduct<G1, G2> {
    return DirectProduct<G1, G2>(a._1 * b._1, a._2 * b._2)
}
