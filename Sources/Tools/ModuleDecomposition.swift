//
//  ModuleDecomposition.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/11/06.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public extension FreeModule {
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
    
    // https://en.wikipedia.org/wiki/Structure_theorem_for_finitely_generated_modules_over_a_principal_ideal_domain#Invariant_factor_decomposition
    public static func invariantFactorDecomposition(basis: [A], generators A: DynamicMatrix<R>, relations B: DynamicMatrix<R>, transition T: DynamicMatrix<R>) -> (summands: [Summand], transition: DynamicMatrix<R>) {
        assert(basis.count == A.rows) // n
        assert(A.rows == B.rows)      // n ≧ k
        assert(A.cols >= B.cols)      // k ≧ l
        
        let (generators, T2) = calculate(A, B, T)
        let summands = generators.map{ (v, a) -> Summand in
            let z = FreeModule(basis: basis, components: v.grid)
            return Summand(z, a)
        }
        
        return (summands, T2)
    }
    
    private static func calculate(_ A: DynamicMatrix<R>, _ B: DynamicMatrix<R>, _ T: DynamicMatrix<R>) -> (generators: [(DynamicColVector<R>, R)], transition: DynamicMatrix<R>) {
        
        let (k, l) = (A.cols, B.cols) // n >= k >= l
        
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
