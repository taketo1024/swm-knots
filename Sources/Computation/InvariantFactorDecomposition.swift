//
//  InvariantFactorDecomposition.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/12.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

//  see: https://en.wikipedia.org/wiki/Structure_theorem_for_finitely_generated_modules_over_a_principal_ideal_domain#Invariant_factor_decomposition

import Foundation

public extension ModuleStructure where R: EuclideanRing {
    
    public static func invariantFactorDecomposition<A: FreeModuleBase>(generators: [A], generatingMatrix A: ComputationalMatrix<R>, relationMatrix B: ComputationalMatrix<R>, transitionMatrix T: ComputationalMatrix<R>) -> DecomposedModuleStructure<A, R> {
        
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
        
        let E  = R1.eliminate(form: .Smith)
        
        let divisors = (E.diagonal + Array(repeating: R.zero, count: k - l)).filter{ $0 != R.identity }
        let s = divisors.count
        
        let A2 = A * E.leftInverse.submatrix(colRange: (k - s) ..< k)
        let T2 = E.left.submatrix(rowRange: (k - s) ..< k) * T
        
        // create summands
        
        let newGenerators = A2.generateElements(from: generators)
        let summands = zip(newGenerators, divisors).map { (z, a) in
            return DecomposedModuleStructure<A, R>.Summand(z, a)
        }

        return DecomposedModuleStructure(generators: generators, summands: summands, transitionMatrix: T2)
    }
}
