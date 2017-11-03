//
//  Homology.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias   Homology<A: FreeModuleBase, R: EuclideanRing> = _Homology<Descending, A, R>
public typealias Cohomology<A: FreeModuleBase, R: EuclideanRing> = _Homology<Ascending, A, R>

public final class _Homology<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: CustomStringConvertible {
    public let chainComplex: _ChainComplex<chainType, A, R>
    internal let groupInfos: [HomologyGroupInfo<chainType, A, R>]
    
    public subscript(i: Int) -> HomologyGroupInfo<chainType, A, R> {
        return groupInfos[i]
    }
    
    public init(chainComplex: _ChainComplex<chainType, A, R>, groups: [HomologyGroupInfo<chainType, A, R>]) {
        self.chainComplex = chainComplex
        self.groupInfos = groups
    }
    
    public convenience init(_ chainComplex: _ChainComplex<chainType, A, R>) {
        let offset = chainComplex.offset
        let top = chainComplex.topDegree
        
        let groups = (offset ... top).map {
            HomologyGroupInfo(chainComplex, degree: $0)
        }
        
        self.init(chainComplex: chainComplex, groups: groups)
    }
    
    public var description: String {
        return "{" + groupInfos.map{"\($0.degree):\($0)"}.joined(separator: ", ") + "}"
    }
    
    public var detailDescription: String {
        return "{\n"
            + groupInfos.map{"\t\($0.degree) : \($0.detailDescription)"}.joined(separator: ",\n")
            + "\n}"
    }
}

public extension _Homology where chainType == Descending, R == IntegerNumber {
    public func bettiNumer(i: Int) -> Int {
        return groupInfos[i].summands.filter{ $0.isFree }.count
    }
    
    public var eulerCharacteristic: Int {
        return (0 ... chainComplex.topDegree).reduce(0){ $0 + (($1 % 2 == 0) ? 1 : -1) * bettiNumer(i: $1) }
    }
}
