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

public typealias   Homology<A: FreeModuleBase, R: EuclideanRing> = _Homology<Descending, A, R>
public typealias Cohomology<A: FreeModuleBase, R: EuclideanRing> = _Homology<Ascending, A, R>

// TODO abstract as `GradedModule`
public final class _Homology<T: ChainType, A: FreeModuleBase, R: EuclideanRing>: AlgebraicStructure {
    public typealias Cycle = FreeModule<A, R>
    
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
            return Summand.zero(self)
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
        let (A1, A2) = (C.boundaryMatrix(i), C.boundaryMatrix(T.descending ? i + 1 : i - 1))
        let (E1, E2) = (A1.eliminate(), A2.eliminate())
        
        let S = SimpleModuleStructure.invariantFactorDecomposition(
            generators:       basis,
            generatingMatrix: E1.kernelMatrix,
            relationMatrix:   E2.imageMatrix,
            transitionMatrix: E1.kernelTransitionMatrix
        )

        return Summand(self, S)
    }
    
    public class Summand: AlgebraicStructure {
        internal var homology: _Homology<T, A, R> // FIXME circular reference!
        public let structure: SimpleModuleStructure<A, R>
        
        internal init(_ H: _Homology<T, A, R>, _ structure: SimpleModuleStructure<A, R>) {
            self.homology = H
            self.structure = structure
        }
        
        internal static func zero(_ H: _Homology<T, A, R>) -> Summand {
            return Summand(H, SimpleModuleStructure.zeroModule)
        }
        
        public var isTrivial: Bool {
            return structure.isTrivial
        }
        
        public var isFree: Bool {
            return structure.isFree
        }
        
        public var rank: Int {
            return structure.rank
        }
        
        public var summands: [SimpleModuleStructure<A, R>.Summand] {
            return structure.summands
        }
        
        public func generator(_ i: Int) -> _HomologyClass<T, A, R> {
            return _HomologyClass(structure.generator(i), homology)
        }
        
        public var generators: [_HomologyClass<T, A, R>] {
            return (0 ..< summands.count).map{ i in generator(i) }
        }
        
        public func torsion(_ i: Int) -> R {
            return structure.torsion(i)
        }
        
        public var zero: _HomologyClass<T, A, R> {
            return _HomologyClass.zero
        }
        
        public func factorize(_ z: Cycle) -> [R] {
            return structure.factorize(z)
        }
        
        public func cycleIsNullHomologous(_ z: Cycle) -> Bool {
            return structure.elementIsZero(z)
        }
        
        public func cyclesAreHomologous(_ z1: Cycle, _ z2: Cycle) -> Bool {
            return cycleIsNullHomologous(z1 - z2)
        }
        
        public static func ==(lhs: _Homology<T, A, R>.Summand, rhs: _Homology<T, A, R>.Summand) -> Bool {
            return lhs.structure == rhs.structure
        }
        
        public var description: String {
            return structure.description
        }
        
        public var detailDescription: String {
            return structure.detailDescription
        }
    }
}
