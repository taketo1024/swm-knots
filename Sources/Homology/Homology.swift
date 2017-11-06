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

public final class _Homology<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: Structure {
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
        return a.chainComplex == b.chainComplex
    }
    
    public var description: String {
        return (chainType.descending ? "H" : "cH") + "(\(chainComplex.name); \(R.symbol))"
    }
    
    public var detailDescription: String {
        return (chainType.descending ? "H" : "cH") + "(\(chainComplex.name); \(R.symbol)) = {\n"
            + (offset ... topDegree).map{ self[$0] }.map{ g in "\t\(g.degree) : \(g.detailDescription)"}.joined(separator: ",\n")
            + "\n}"
    }
    
    public final class HomologySummand: FinitelyGeneratedModuleStructure<A, R> {
        public let degree: Int
        
        public init(_ i: Int, _ C: _ChainComplex<chainType, A, R>) {
            let basis = C.chainBasis(i)
            
            // Z = Ker(A1), B = Im(A2)
            // T: Transition matrix from C to Z (represents cycles in Z-coords.)
            //
            //   P * A1 * Q = [D; O_k]
            //   =>  Z = Q[ * , n - k ..< n] = Q * [O_(n-k); I_k]
            //   =>  Q^-1 * Z = [O; I_k]
            //
            // Put T = Q^-1[ * , n - k ..< n], then T * Z = I_k.
            
            let (A1, A2) = (C.boundaryMatrix(i), C.boundaryMatrix(chainType.descending ? i + 1 : i - 1))
            let (Z, B) = (A1.kernelMatrix, A2.imageMatrix)
            let T = A1.smithNormalForm.rightInverse.submatrix(rowsInRange: (Z.rows - Z.cols) ..< Z.rows) as DynamicMatrix<R>
            
            self.degree = i
            super.init(basis: basis, generators: Z, relations: B, transition: T)
        }
        
        public var generators: [Cycle] {
            return self.map{ s in s.generator }
        }
        
        public var rank: Int {
            return self.filter{ $0.isFree }.count
        }
        
        public func factorize(_ z: Cycle) -> [R] {
            let n = basis.count
            let v = transitionMatrix * ColVector(rows: n, grid: z.factorize(by: basis))
            
            return self.enumerated().map { (i, s) in
                return s.isFree ? v[i] : v[i] % s.factor
            }
        }
        
        public func isNullHomologue(_ z: Cycle) -> Bool {
            return factorize(z).forAll{ $0 == 0 }
        }
        
        public func isHomologue(_ z1: Cycle, _ z2: Cycle) -> Bool {
            return isNullHomologue(z1 - z2)
        }
        
        public var detailDescription: String {
            return "\(self),\t\(self.map{ $0.generator })"
        }
    }
}

public extension Homology where chainType == Descending {
    public func bettiNumer(i: Int) -> Int {
        return self[i].filter{ $0.isFree }.count
    }
    
    public var eulerNumber: Int {
        return (0 ... chainComplex.topDegree).reduce(0){ $0 + (-1).pow($1) * bettiNumer(i: $1) }
    }
}
