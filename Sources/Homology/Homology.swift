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

public final class _Homology<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: CustomStringConvertible, CustomDebugStringConvertible {
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
        typealias M = FreeModule<A, R>
        
        let offset = chainComplex.offset
        let degree = chainComplex.degree
        
        let elims = { () -> (Int) -> MatrixElimination<R, Dynamic, Dynamic> in
            let res = (offset - 1 ... degree + 1).map { chainComplex.boundaryMap($0).matrix.eliminate() }
            return { (i: Int) -> MatrixElimination<R, Dynamic, Dynamic> in
                return res[i - offset + 1]
            }
        }()
        
        let groups = (offset ... degree).map { (i) -> HomologyGroupInfo<chainType, A, R> in
            HomologyGroupInfo(degree: i,
                              basis: chainComplex.chainBasis(i),
                              elim1: elims(i),
                              elim2: chainComplex.descending ? elims(i + 1) : elims(i - 1))
        }
        
        self.init(chainComplex: chainComplex, groups: groups)
    }
    
    public var description: String {
        return "{" + groupInfos.map{"\($0.degree):\($0)"}.joined(separator: ", ") + "}"
    }
    
    public var debugDescription: String {
        return "{\n"
            + groupInfos.map{"\t\($0.degree) : \($0.debugDescription)"}.joined(separator: ",\n")
            + "\n}"
    }
}

public extension _Homology where chainType == Descending, R == IntegerNumber {
    public func bettiNumer(i: Int) -> Int {
        return groupInfos[i].summands.filter{ $0.isFree }.count
    }
    
    public var eulerCharacteristic: Int {
        return (0 ... chainComplex.degree).reduce(0){ $0 + (($1 % 2 == 0) ? 1 : -1) * bettiNumer(i: $1) }
    }
}
