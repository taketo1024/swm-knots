//
//  Homology.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct Homology<A: FreeModuleBase, R: Ring>: CustomStringConvertible {
    public let chainComplex: ChainComplex<A, R>
    public let groups: [FreeModuleQuotient<A, R>]
    
    public init(_ chainComplex: ChainComplex<A, R>) {
        self.chainComplex = chainComplex
        self.groups = []
    }
    
    public func bettiNumer(i: Int) -> Int {
        return groups[i].generators.filter{ $0.isFree }.count
    }
    
    public var eulerCharacteristic: Int {
        return (0 ... chainComplex.dim).reduce(0){ $0 + (($1 % 2 == 0) ? 1 : -1) * bettiNumer(i: $1) }
    }
    
    public var description: String {
        return "{" + groups.enumerated().map{"\($0):\($1)"}.joined(separator: ", ") + "}"
    }
    
    public var detailDescription: String {
        return "{\n"
            + groups.enumerated().map{"\t\($0) : \($1),\t\($1.generators.map{$0.generator})"}.joined(separator: ",\n")
            + "\n}, eulerChacteristic: \(eulerCharacteristic)"
    }
}

public extension Homology where R: EuclideanRing {
    public init(_ chainComplex: ChainComplex<A, R>) {
        self.chainComplex = chainComplex
        self.groups = (0 ... chainComplex.dim).map { i in
            let d0 = chainComplex.boundaryMap(i)
            let d1 = chainComplex.boundaryMap(i + 1)
            
            let b = d0.domainBasis                // basis of the i-th Chain group C_i
            let Z = d0.elimination.kernelPart // Z_i in C_i : the i-th Cycle group
            let B = d1.elimination.imagePart  // B_i in Z_i : the i-th Boundary group
            
            return FreeModuleQuotient(basis: b, divident: Z, divisor: B) // H_i = Z_i / B_i : the i-th Homology group

        }
    }
}
