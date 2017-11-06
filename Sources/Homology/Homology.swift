//
//  Homology.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// A class representing the total (co)Homology group for a given ChainComplex.
// Consists of the direct-sum of HomologySummands:
//
//   H = H_0 ⊕ H_1 ⊕ ... ⊕ H_n
//
// where each HomologySummand is decomposed into invariant factors:
//
//   H_i = (R/(a_1) ⊕ ... ⊕ R/(a_t)) ⊕ (R ⊕ ... ⊕ R)
//

public typealias   Homology<A: FreeModuleBase, R: EuclideanRing> = _Homology<Descending, A, R>
public typealias Cohomology<A: FreeModuleBase, R: EuclideanRing> = _Homology<Ascending, A, R>

public final class _Homology<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: Equatable, Structure {
    public typealias Cycle = FreeModule<A, R>
    
    public let chainComplex: _ChainComplex<chainType, A, R>
    private var _summands: [HomologySummand?]
    
    public subscript(i: Int) -> HomologySummand {
        guard (offset ... topDegree).contains(i) else {
            fatalError() // TODO return empty info
        }
        
        if let g = _summands[i - offset] {
            return g
        } else {
            let g = HomologySummand(i, chainComplex)
            _summands[i - offset] = g
            return g
        }
    }
    
    public init(_ chainComplex: _ChainComplex<chainType, A, R>) {
        self.chainComplex = chainComplex
        self._summands = Array(repeating: nil, count: chainComplex.topDegree - chainComplex.offset + 1) // lazy init
    }
    
    public var offset: Int {
        return chainComplex.offset
    }
    
    public var topDegree: Int {
        return chainComplex.topDegree
    }
    
    public static func ==(a: _Homology<chainType, A, R>, b: _Homology<chainType, A, R>) -> Bool {
        return a.chainComplex.name == b.chainComplex.name // TODO replace with a more precise & efficient way.
    }
    
    public var description: String {
        return (chainType.descending ? "H" : "cH") + "(\(chainComplex.name); \(R.symbol))"
    }
    
    public var detailDescription: String {
        return (chainType.descending ? "H" : "cH") + "(\(chainComplex.name); \(R.symbol)) = {\n"
            + (offset ... topDegree).map{ self[$0] }.map{ g in "\t\(g.degree) : \(g.detailDescription)"}.joined(separator: ",\n")
            + "\n}"
    }
    
    public final class HomologySummand: Structure {
        public typealias Summand = Cycle.Summand
        
        public let degree: Int
        public let chainBasis: [A]
        public let summands: [Summand]
        public let transitionMatrix: DynamicMatrix<R> // chain -> cycle

        internal init(_ i: Int, _ C: _ChainComplex<chainType, A, R>) {
            let basis = C.chainBasis(i)
            
            let (A1, A2) = (C.boundaryMatrix(i), C.boundaryMatrix(chainType.descending ? i + 1 : i - 1))
            
            let (Z, B) = (A1.kernelMatrix, A2.imageMatrix)
            
            // T: Transition matrix from C to Z (represents cycles in Z-coords.)
            //
            //   P * A1 * Q = [D; O_k]
            //   =>  Z = Q[ * , n - k ..< n] = Q * [O_(n-k); I_k]
            //   =>  Q^-1 * Z = [O; I_k]
            //
            // Put T = Q^-1[ * , n - k ..< n], then T * Z = I_k.
            
            let T1 = A1.smithNormalForm.rightInverse.submatrix(rowsInRange: (Z.rows - Z.cols) ..< Z.rows) as DynamicMatrix<R>
            
            let (summands, T2) = Cycle.invariantFactorDecomposition(basis: basis, generators: Z, relations: B, transition: T1)
            
            self.degree = i
            self.chainBasis = basis
            self.summands = summands
            self.transitionMatrix = T2
        }
        
        public subscript (i: Int) -> Summand {
            return summands[i]
        }
        
        public var generators: [Cycle] {
            return summands.map{ s in s.generator }
        }
        
        public var rank: Int {
            return summands.filter{ $0.isFree }.count
        }
        
        public func factorize(_ z: Cycle) -> [R] {
            let n = chainBasis.count
            let v = transitionMatrix * ColVector(rows: n, grid: z.factorize(by: chainBasis))
            
            return summands.enumerated().map { (i, s) in
                return s.isFree ? v[i] : v[i] % s.factor
            }
        }
        
        public func isNullHomologue(_ z: Cycle) -> Bool {
            return factorize(z).forAll{ $0 == 0 }
        }
        
        public func isHomologue(_ z1: Cycle, _ z2: Cycle) -> Bool {
            return isNullHomologue(z1 - z2)
        }
        
        public var description: String {
            let desc = summands.map{$0.description}.joined(separator: "⊕")
            return desc.isEmpty ? "0" : desc
        }
        
        public var detailDescription: String {
            return "\(self),\t\(summands.map{ $0.generator })"
        }
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
