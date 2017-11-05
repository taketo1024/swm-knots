//
//  HomologyGroupInfo.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/18.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class HomologyGroupInfo<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: TypeInfo {
    public struct Summand: CustomStringConvertible {
        public let generator: FreeModule<A, R>
        public let factor: R
        
        internal init(_ generator: FreeModule<A, R>, _ factor: R) {
            self.generator = generator
            self.factor = factor
        }
        
        public var isFree: Bool {
            return factor == R.zero
        }
        
        public var description: String {
            switch isFree {
            case true : return R.symbol
            case false: return "\(R.symbol)/\(factor)"
            }
        }
    }
    
    public let degree: Int
    public let chainBasis: [A]
    public let summands: [Summand]
    public let transitionMatrix: DynamicMatrix<R> // chain -> cycle
    
    private typealias Cycle = FreeModule<A, R>
    
    public init(_ C: _ChainComplex<chainType, A, R>, degree i: Int) {
        let basis = C.chainBasis(i)
        let (A1, A2) = (C.boundaryMatrix(i), C.boundaryMatrix(chainType.descending ? i + 1 : i - 1))
        let (_summands, T) = HomologyGroupInfo.calculate(A1, A2)
        
        self.degree = i
        self.chainBasis = basis
        self.summands = _summands.map{ (v, a) in
            let z = Cycle(basis: basis, components: v.grid)
            return Summand(z, a)
        }
        self.transitionMatrix = T
    }
    
    public subscript (i: Int) -> Summand {
        return summands[i]
    }
    
    public var rank: Int {
        return summands.filter{ $0.isFree }.count
    }
    
    public var torsions: Int {
        return summands.count - rank
    }
    
    public func components(_ z: FreeModule<A, R>) -> [R] {
        let n = chainBasis.count
        let v = transitionMatrix * ColVector(rows: n, grid: chainBasis.map{ z[$0] })
        
        return summands.enumerated().map { (i, s) in
            return s.isFree ? v[i] : v[i] % s.factor
        }
    }
    
    public func isHomologue(_ z1: FreeModule<A, R>, _ z2: FreeModule<A, R>) -> Bool {
        return isNullHomologue(z1 - z2)
    }
    
    public func isNullHomologue(_ z: FreeModule<A, R>) -> Bool {
        return components(z).forAll{ $0 == 0 }
    }
    
    public var description: String {
        let desc = summands.map{$0.description}.joined(separator: "⊕")
        return desc.isEmpty ? "0" : desc
    }
    
    public var detailDescription: String {
        return "\(self),\t\(summands.map{ $0.generator })"
    }
    
    // H_i = Ker(d1) / Im(d2)
    private static func calculate(_ A1: DynamicMatrix<R>, _ A2: DynamicMatrix<R>) -> (summands: [(DynamicColVector<R>, R)], T: DynamicMatrix<R>) {
        
        // Z: Matrix representing the Cyclic group
        
        let Z = A1.kernelMatrix
        let (n, k) = (Z.rows, Z.cols)
        
        // B: Matrix representing the Boundary group
        
        let B = A2.imageMatrix
        let l = B.cols // l <= k, B ⊂ Z
        
        // T: Transition matrix from C to Z (represents cycles in Z-coords.)
        //
        //   A1 --> P * A1 * Q = [D; O_k], the Smith normal form of A1
        //   =>  Z = ( n - k ..< n cols of Q ) = Q * [O_(n-k); I_k]
        //   =>  Q^-1 * Z = [O; I_k]
        //   =>  T := ( n - k ..< n cols of Q^-1),
        //       T * Z = I_k, i.e. T * z_i = e_i.
        
        let T1: DynamicMatrix<R> = A1.smithNormalForm.rightInverse.submatrix(rowsInRange: n - k ..< n)
        
        // R: Relation from Z to B, in M_(k,l).
        //
        //   B = Z * R  (b_j = Σ z_i * r_ij)
        //   => T * B = T * Z * R = I_k * R = R.
        //
        // R essensially gives the structure of H = Z/B
        
        let R1 = T1 * B
        
        // Retake bases of Z and B to obtain the decomposition of H.
        //
        //   R --> P' * R * Q' = [D'; O].
        //   => (B * Q') = (Z * R) * Q' = (Z * P'^-1) * [D'; O]
        //
        // D' gives the relation between the new bases.
        // The transition matrix from C to Z' = (Z * P'^-1) is given by
        //
        //   T' := P' * T
        //     => T' * Z' = (P' * T) * (Z * P'^-1) = I_k,
        //        i.e.  T' * z'_i = e_i.
        //
        // eg)    D' = [1,   1,   2,   0]
        //     => H  =  0  + 0 + Z/2 + Z

        
        let E  = R1.smithNormalForm
        let factors = (E.diagonal + Array(repeating: R.zero, count: k - l)).filter{ $0 != R.identity }
        let s = factors.count
        
        let Z2 = Z * (E.leftInverse.submatrix(colsInRange: (k - s) ..< k) as DynamicMatrix<R>)
        let T2 = (E.left.submatrix(rowsInRange: (k - s) ..< k) as DynamicMatrix<R>) * T1
        
        let summands = factors.enumerated().map{ (j, a) in (Z2.colVector(j), a) }
        return (summands, T2)
    }
}
