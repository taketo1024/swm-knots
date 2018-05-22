//
//  AbstractSimpleModuleStructure.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/05/22.
//

import Foundation

public typealias AbstractSimpleModuleStructure<R: EuclideanRing> = SimpleModuleStructure<AbstractBasisElement, R>

public extension AbstractSimpleModuleStructure where A == AbstractBasisElement, R: EuclideanRing {
    public convenience init(rank r: Int, torsions: [R] = []) {
        let t = torsions.count
        let basis = (0 ..< r + t).map{ i in A(i) }
        let summands = (0 ..< r).map{ i in Summand(basis[i], .zero) }
            + torsions.enumerated().map{ (i, d) in Summand(basis[i + r], d) }
        let I = Matrix<R>.identity(size: r + t)
        self.init(summands, basis, I)
    }
    
    public static func ⊕(a: AbstractSimpleModuleStructure<R>, b: AbstractSimpleModuleStructure<R>) -> AbstractSimpleModuleStructure<R> {
        return AbstractSimpleModuleStructure(
            rank: a.rank + b.rank,
            torsions: a.torsionCoeffs + b.torsionCoeffs
        )
    }
}

public extension SimpleModuleStructure where R: EuclideanRing {
    public var asAbstract: AbstractSimpleModuleStructure<R> {
        let torsions = summands.filter{!$0.isFree}.map{$0.divisor}
        return AbstractSimpleModuleStructure(rank: rank, torsions: torsions)
    }
}
