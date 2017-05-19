//
//  Homology.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias Homology<A: FreeModuleBase, R: Ring> = BaseHomology<DescendingChainType, A, R>
public typealias Cohomology<A: FreeModuleBase, R: Ring> = BaseHomology<AscendingChainType, A, R>

public struct BaseHomology<chainType: ChainType, A: FreeModuleBase, R: Ring>: CustomStringConvertible {
    public let chainComplex: BaseChainComplex<chainType, A, R>
    public let groups: [FreeModuleQuotient<A, R>]
    
    public init(chainComplex: BaseChainComplex<chainType, A, R>, groups: [FreeModuleQuotient<A, R>]) {
        self.chainComplex = chainComplex
        self.groups = groups
    }
    
    public var description: String {
        return "{" + groups.enumerated().map{"\($0):\($1)"}.joined(separator: ", ") + "}"
    }
    
    public var detailDescription: String {
        return "{\n"
            + groups.enumerated().map{"\t\($0) : \($1),\t\($1.generators.map{$0.generator})"}.joined(separator: ",\n")
            + "\n}"
    }
}

public extension BaseHomology where R: EuclideanRing {
    public init(_ chainComplex: BaseChainComplex<chainType, A, R>) {
        let descending = (chainType.self == DescendingChainType.self)
        let dim = chainComplex.dim
        let elims = chainComplex.boundaryMaps.map { $0.matrix.eliminate() }

        let groups: [FreeModuleQuotient<A, R>] = (0 ... dim).map { i in
            let map = chainComplex.boundaryMaps[i]
            let basis = map.domainBasis // basis of the i-th Chain group C_i
            
            let Z = elims[i].kernelPart     // Z_i in C_i : the i-th Cycle group
            
            let j = (descending) ? (i + 1) : (i - 1)
            let B = (0 <= j && j < elims.count) ? elims[j].imagePart : TypeLooseMatrix(rows: basis.count, cols: 0, grid:[])  // B_i in Z_i : the i-th Boundary group
            
            return FreeModuleQuotient(basis: basis, divident: Z, divisor: B) // H_i = Z_i / B_i : the i-th Homology group
        }

        self.init(chainComplex: chainComplex, groups: groups)
    }
}

public extension BaseHomology where chainType == DescendingChainType, R == IntegerNumber {
    public func bettiNumer(i: Int) -> Int {
        return groups[i].generators.filter{ $0.isFree }.count
    }
    
    public var eulerCharacteristic: Int {
        return (0 ... chainComplex.dim).reduce(0){ $0 + (($1 % 2 == 0) ? 1 : -1) * bettiNumer(i: $1) }
    }
}
