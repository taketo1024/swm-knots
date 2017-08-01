//
//  Homology.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias   Homology<R: EuclideanRing, A: FreeModuleBase> = _Homology<Descending, R, A>
public typealias Cohomology<R: EuclideanRing, A: FreeModuleBase> = _Homology<Ascending, R, A>

public final class _Homology<chainType: ChainType, R: EuclideanRing, A: FreeModuleBase>: CustomStringConvertible, CustomDebugStringConvertible {
    public let chainComplex: _ChainComplex<chainType, R, A>
    internal let groupInfos: [HomologyGroupInfo<chainType, R, A>]
    
    public subscript(i: Int) -> HomologyGroupInfo<chainType, R, A> {
        return groupInfos[i]
    }
    
    public init(chainComplex: _ChainComplex<chainType, R, A>, groups: [HomologyGroupInfo<chainType, R, A>]) {
        self.chainComplex = chainComplex
        self.groupInfos = groups
    }
    
    public convenience init(_ chainComplex: _ChainComplex<chainType, R, A>) {
        typealias M = FreeModule<R, A>
        
        let offset = chainComplex.offset
        let top = chainComplex.topDegree
        
        let elims = { () -> (Int) -> MatrixElimination<R, Dynamic, Dynamic> in
            let res = (offset - 1 ... top + 1).map { chainComplex.boundaryMap($0).matrix.eliminate() }
            return { (i: Int) -> MatrixElimination<R, Dynamic, Dynamic> in
                return res[i - offset + 1]
            }
        }()
        
        let groups = (offset ... top).map { (i) -> HomologyGroupInfo<chainType, R, A> in
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
        return (0 ... chainComplex.topDegree).reduce(0){ $0 + (($1 % 2 == 0) ? 1 : -1) * bettiNumer(i: $1) }
    }
}
