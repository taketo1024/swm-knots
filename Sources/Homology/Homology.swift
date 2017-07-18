//
//  Homology.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias Homology<A: FreeModuleBase, R: EuclideanRing> = BaseHomology<DescendingChainType, A, R>
public typealias Cohomology<A: FreeModuleBase, R: EuclideanRing> = BaseHomology<AscendingChainType, A, R>

public struct BaseHomology<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: CustomStringConvertible {
    public let chainComplex: BaseChainComplex<chainType, A, R>
    internal let groupInfos: [HomologyGroupInfo<chainType, A, R>]
    
    public subscript(i: Int) -> HomologyGroupInfo<chainType, A, R> {
        return groupInfos[i]
    }
    
    public init(chainComplex: BaseChainComplex<chainType, A, R>, groups: [HomologyGroupInfo<chainType, A, R>]) {
        self.chainComplex = chainComplex
        self.groupInfos = groups
    }
    
    public init(_ chainComplex: BaseChainComplex<chainType, A, R>) {
        typealias M = FreeModule<A, R>
        
        let offset = chainComplex.offset
        let dim    = chainComplex.dim
        
        let elims = { () -> (Int) -> MatrixElimination<R, Dynamic, Dynamic> in
            let res = (offset - 1 ... dim + 1).map { chainComplex.boundaryMap($0).matrix.eliminate() }
            return { (i: Int) -> MatrixElimination<R, Dynamic, Dynamic> in
                return res[i - offset + 1]
            }
        }()
        
        let groups = (offset ... dim).map { (i) -> HomologyGroupInfo<chainType, A, R> in
            HomologyGroupInfo(dim: i,
                              basis: chainComplex.chainBasis(i),
                              elim1: elims(i),
                              elim2: chainComplex.descending ? elims(i + 1) : elims(i - 1))
        }
        
        self.init(chainComplex: chainComplex, groups: groups)
    }
    
    public var description: String {
        return "{" + groupInfos.map{"\($0.dim):\($0)"}.joined(separator: ", ") + "}"
    }
    
    public var detailDescription: String {
        return "{\n"
            + groupInfos.map{"\t\($0.dim) : \($0.detailDescription)"}.joined(separator: ",\n")
            + "\n}"
    }
}

public extension BaseHomology where chainType == DescendingChainType, R == IntegerNumber {
    public func bettiNumer(i: Int) -> Int {
        return groupInfos[i].summands.filter{ $0.isFree }.count
    }
    
    public var eulerCharacteristic: Int {
        return (0 ... chainComplex.dim).reduce(0){ $0 + (($1 % 2 == 0) ? 1 : -1) * bettiNumer(i: $1) }
    }
}
