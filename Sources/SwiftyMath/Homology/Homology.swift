//
//  Homology.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/05/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// A class representing the total (co)Homology group for a given ChainComplex.
// Consists of the direct-sum of i-th Homology groups:
//
//   H = H_0 ⊕ H_1 ⊕ ... ⊕ H_n
//
// where each group is decomposed into invariant factors:
//
//   H_i = (R/(a_1) ⊕ ... ⊕ R/(a_t)) ⊕ (R ⊕ ... ⊕ R)
//

public typealias   Homology<A: BasisElementType, R: EuclideanRing> = _Homology<Descending, A, R>
public typealias Cohomology<A: BasisElementType, R: EuclideanRing> = _Homology<Ascending, A, R>

// TODO abstract as `GradedModule`
public final class _Homology<T: ChainType, A: BasisElementType, R: EuclideanRing>: AlgebraicStructure {
    public typealias Cycle = FreeModule<A, R>
    public typealias Summand = SimpleModuleStructure<A, R>
    
    public let name: String
    public let chainComplex: _ChainComplex<T, A, R>
    private var _summands: [Summand?]
    
    public init(name: String? = nil, chainComplex: _ChainComplex<T, A, R>) {
        self.name = name ?? "\(T.descending ? "H" : "cH")(\(chainComplex.name))"
        self.chainComplex = chainComplex
        self._summands = Array(repeating: nil, count: chainComplex.topDegree - chainComplex.offset + 1) // lazy init
    }
    
    public subscript(i: Int) -> Summand {
        guard (offset ... topDegree).contains(i) else {
            return Summand.zeroModule
        }
        
        if let g = _summands[i - offset] {
            return g
        } else {
            let g = generateSummand(i)
            _summands[i - offset] = g
            return g
        }
    }
    
    public var offset: Int {
        return chainComplex.offset
    }
    
    public var topDegree: Int {
        return chainComplex.topDegree
    }
    
    public func bettiNumer(_ i: Int) -> Int {
        return self[i].rank
    }
    
    public var eulerCharacteristic: Int {
        return (offset ... topDegree).sum{ i in (-1).pow(i) * bettiNumer(i) }
    }
    
    public var gradedEulerCharacteristic: LaurentPolynomial<R> {
        let q = LaurentPolynomial<R>.indeterminate
        return (offset ... topDegree).sum { i -> LaurentPolynomial<R> in
            R(from: (-1).pow(i)) * self[i].summands.sum { s -> LaurentPolynomial<R> in
                s.isFree ? q.pow(s.generator.degree) : .zero
            }
        }
    }
    
    public func homologyClass(_ z: Cycle) -> _HomologyClass<T, A, R> {
        return _HomologyClass(z, self)
    }

    public static func ==(a: _Homology<T, A, R>, b: _Homology<T, A, R>) -> Bool {
        return (a.offset == b.offset) && (a.topDegree == b.topDegree) && (a.offset ... a.topDegree).forAll { i in a[i] == b[i] }
    }
    
    public var description: String {
        return name
    }
    
    public var detailDescription: String {
        return name + " = {\n"
            + (offset ... topDegree).map{ i in (i, self[i]) }
                .map{ (i, g) in "\t\(i) : \(g.detailDescription)"}
                .joined(separator: ",\n")
            + "\n}"
    }
    
    private func generateSummand(_ i: Int) -> Summand {
        let C = chainComplex
        let basis = C.chainBasis(i)
        let (Ain, Aout) = (C.boundaryMatrix(i - T.degree), C.boundaryMatrix(i))
        let (Ein, Eout) = (Ain.eliminate(), Aout.eliminate())
        
        return SimpleModuleStructure.invariantFactorDecomposition(
            generators:       basis,
            generatingMatrix: Eout.kernelMatrix,
            relationMatrix:   Ein.imageMatrix,
            transitionMatrix: Eout.kernelTransitionMatrix
        )
    }
}
