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
    private var groups: [HomologyGroupInfo<chainType, A, R>?]
    
    public subscript(i: Int) -> HomologyGroupInfo<chainType, A, R> {
        guard (offset ... topDegree).contains(i) else {
            fatalError() // TODO return empty info
        }
        
        if let g = groups[i - offset] {
            return g
        } else {
            let g = HomologyGroupInfo(chainComplex, degree: i)
            groups[i - offset] = g
            return g
        }
    }
    
    public init(_ chainComplex: _ChainComplex<chainType, A, R>) {
        self.chainComplex = chainComplex
        self.groups = Array(repeating: nil, count: chainComplex.topDegree - chainComplex.offset + 1)
    }
    
    private var offset: Int {
        return chainComplex.offset
    }
    
    public var topDegree: Int {
        return chainComplex.topDegree
    }
    
    public var description: String {
        return (chainType.descending ? "H" : "cH") + "(\(chainComplex.name); \(R.symbol))"
    }
    
    public var detailDescription: String {
        return (chainType.descending ? "H" : "cH") + "(\(chainComplex.name); \(R.symbol)) = {\n"
            + (offset ... topDegree).map{ self[$0] }.map{ g in "\t\(g.degree) : \(g.detailDescription)"}.joined(separator: ",\n")
            + "\n}"
    }
}

public extension Homology where chainType == Descending {
    public func bettiNumer(i: Int) -> Int {
        return self[i].summands.filter{ $0.isFree }.count
    }
    
    public var eulerNumber: Int {
        return (0 ... chainComplex.topDegree).reduce(0){ $0 + (-1).pow($1) * bettiNumer(i: $1) }
    }
}
