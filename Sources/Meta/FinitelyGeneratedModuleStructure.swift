//
//  ModuleDecomposition.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/06.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// https://en.wikipedia.org/wiki/Structure_theorem_for_finitely_generated_modules_over_a_principal_ideal_domain#Invariant_factor_decomposition

public class FinitelyGeneratedModuleStructure<A: FreeModuleBase, R: EuclideanRing>: Structure, Sequence {
    public let basis: [A]
    public let summands: [Summand]
    public let transitionMatrix: DynamicMatrix<R>
    
    public init(basis: [A], generators A: DynamicMatrix<R>, relations B: DynamicMatrix<R>, transition T1: DynamicMatrix<R>) {
        let (generators, T2) = FinitelyGeneratedModuleStructure<A, R>.calculate(A, B, T1)
        
        let summands = generators.map{ (v, a) -> Summand in
            let z = FreeModule(basis: basis, vector: v)
            return Summand(z, a)
        }
        
        self.basis = basis
        self.summands = summands
        self.transitionMatrix = T2
    }
    
    public convenience init(basis: [A], relations B: DynamicMatrix<R>) {
        let n = basis.count
        let I = DynamicMatrix<R>.identity(size: n)
        self.init(basis: basis, generators: I, relations: B, transition: I)
    }
    
    public subscript(i: Int) -> Summand {
        return summands[i]
    }
    
    public func makeIterator() -> IndexingIterator<[Summand]> {
        return summands.makeIterator()
    }
    
    public static func ==(a: FinitelyGeneratedModuleStructure<A, R>, b: FinitelyGeneratedModuleStructure<A, R>) -> Bool {
        return a.summands == b.summands
    }
    
    public var description: String {
        return summands.isEmpty ? "0" : summands.map{$0.description}.joined(separator: "⊕")
    }

    public final class Summand: Structure {
        public let generator: FreeModule<A, R>
        public let factor: R
        
        internal init(_ generator: FreeModule<A, R>, _ factor: R) {
            self.generator = generator
            self.factor = factor
        }
        
        public var isFree: Bool {
            return factor == R.zero
        }
        
        public static func ==(a: Summand, b: Summand) -> Bool {
            return (a.generator, a.factor) == (b.generator, b.factor)
        }
        
        public var description: String {
            switch isFree {
            case true : return R.symbol
            case false: return "\(R.symbol)/\(factor)"
            }
        }
    }
    
    private static func calculate(_ A: DynamicMatrix<R>, _ B: DynamicMatrix<R>, _ T: DynamicMatrix<R>) -> (generators: [(DynamicColVector<R>, R)], transition: DynamicMatrix<R>) {
        
        assert(A.rows == B.rows)
        assert(A.rows >= A.cols)  // n ≧ k
        assert(A.cols >= B.cols)  // k ≧ l
        
        let (k, l) = (A.cols, B.cols)
        
        // R ∈ M(k, l) : Relation from A to B,  B = A * R.
        //
        // R = T * B, since
        //     T * A = I_k,
        //     T * B = T * (A * R) = I_k * R = R.
        //
        // R gives the structure of the quotient A / B.
        
        let R1 = T * B
        
        // Retake bases of Z and B to obtain the decomposition of H.
        //
        //   P' * R * Q' = [D'; O].
        //   => (B * Q') = (Z * R) * Q' = (Z * P'^-1) * [D; O]
        //
        // D gives the relation between the new bases.
        //
        // eg)     D = [1,   1,   2,   0]
        //     A / B =  0  + 0 + Z/2 + Z
        //
        // The transition matrix to A' = (A * P'^-1) is given by
        //
        //   T' := P' * T, since
        //   T' * A' = (P' * T) * (Z * P'^-1) = P' * I_k * P'^-1 = I_k.
        //
        
        let E  = R1.smithNormalForm
        let factors = (E.diagonal + Array(repeating: R.zero, count: k - l)).filter{ $0 != R.identity }
        let s = factors.count
        
        let A2 = A * (E.leftInverse.submatrix(colsInRange: (k - s) ..< k) as DynamicMatrix<R>)
        let T2 = (E.left.submatrix(rowsInRange: (k - s) ..< k) as DynamicMatrix<R>) * T
        
        let summands = factors.enumerated().map{ (j, a) in (A2.colVector(j), a) }
        return (summands, T2)
    }
}
