//
//  VectorSpace.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/03/18.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol VectorSpace: Module where CoeffRing: Field { }

public protocol FiniteDimVectorSpace: VectorSpace {
    static var dim: Int { get }
    static var standardBasis: [Self] { get }
    var standardCoordinates: [CoeffRing] { get }
}

public protocol _ProductVectorSpace: VectorSpace, _ProductModule {}

public struct ProductVectorSpace<V1: VectorSpace, V2: VectorSpace>: _ProductVectorSpace where V1.CoeffRing == V2.CoeffRing {
    public typealias Left = V1
    public typealias Right = V2
    public typealias CoeffRing = V1.CoeffRing
    
    public let _1: V1
    public let _2: V2
    
    public init(_ v1: V1, _ v2: V2) {
        self._1 = v1
        self._2 = v2
    }
}
