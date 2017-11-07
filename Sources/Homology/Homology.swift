//
//  Homology.swift
//  SwiftyAlgebra
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

public final class _Homology<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: Structure {
    public typealias Summand = FinitelyGeneratedModuleStructure<A, R>
    public typealias Cycle = FreeModule<A, R>
    
    public let chainComplex: _ChainComplex<chainType, A, R>
    private var _summands: [Summand?]
    
    public subscript(i: Int) -> Summand {
        guard (offset ... topDegree).contains(i) else {
            fatalError() // TODO return empty info
        }
        
        if let g = _summands[i - offset] {
            return g
        } else {
            let g = generateSummand(i)
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
            + (offset ... topDegree).map{ i in (i, self[i]) }
                .map{ (i, g) in "\t\(i) : \(g.detailDescription)"}
                .joined(separator: ",\n")
            + "\n}"
    }
    
    private func generateSummand(_ i: Int) -> Summand {
        let C = chainComplex
        let basis = C.chainBasis(i)
        let (A1, A2) = (C.boundaryMatrix(i), C.boundaryMatrix(chainType.descending ? i + 1 : i - 1))

        // TODO cache elimination result
        
        // Z = Ker(A1)
        let E1 = DiagonalEliminator(A1.copy()).run()
        let Z = E1.right.submatrix(colRange: E1.rank ..< A1.cols)
        
        // B = Im(A2)
        let E2 = DiagonalEliminator(A2.copy()).run()
        let B = E2.leftInverse.submatrix(colRange: 0 ..< E2.rank)
        
        E2.diagonal.enumerated().forEach { (j, a) in
            if j < B.cols {
                B.multiplyCol(at: j, by: a)
            }
        }

        // T: Transition matrix from C to Z (represents cycles in Z-coords.)
        //
        //   P * A1 * Q = [D; O_k]
        //   =>  Z = Q[ * , n - k ..< n] = Q * [O_(n-k); I_k]
        //   =>  Q^-1 * Z = [O; I_k]
        //
        // Put T = Q^-1[ * , n - k ..< n], then T * Z = I_k.
        
        let T = E1.rightInverse.submatrix(rowRange: (Z.rows - Z.cols) ..< Z.rows)
        
        return Summand(basis: basis, generators: Z, relations: B, transition: T)
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
