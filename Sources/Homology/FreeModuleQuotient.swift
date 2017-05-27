//
//  FreeModuleQuotient.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/14.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// TODO endow an algebraic structure. 

public enum FreeModuleQuotientGenerator<A: FreeModuleBase, R: Ring>: CustomStringConvertible {
    case Free(generator: FreeModule<A, R>)
    case Tor(factor: R, generator: FreeModule<A, R>)
    
    public var isFree: Bool {
        switch self{
        case .Free(_)  : return true
        case .Tor(_, _): return false
        }
    }
    
    public var generator: FreeModule<A, R> {
        switch self{
        case let .Free(g)  : return g
        case let .Tor(_, g): return g
        }
    }
    
    public var description: String {
        switch self{
        case .Free(_): return R.symbol
        case let .Tor(f, _): return "\(R.symbol)/\(f)"
        }
    }
}

public struct FreeModuleQuotient<A: FreeModuleBase, R: Ring>: CustomStringConvertible {
    public let generators: [FreeModuleQuotientGenerator<A, R>]
    
    public init(_ generators: [FreeModuleQuotientGenerator<A, R>]) {
        self.generators = generators
    }
    
    public var description: String {
        let desc = generators.map{$0.description}.joined(separator: "⊕")
        return desc.isEmpty ? "0" : desc
    }
}

public extension FreeModuleQuotient where R: EuclideanRing {
    
    private typealias M = FreeModule<A, R>
    
    // e.g. basis = (a, b, c), P = [1, 0; 0, 2; 1, 0]
    //      ==> G = <a, b, c | a + c = 2b = 0>
    
    public init<k:_Int, l:_Int>(basis: [FreeModule<A, R>], relation P: Matrix<R, k, l>) {
        
        // Eliminate P -> QPR = [D; 0].
        // By taking basis * Q^-1 as a new basis, the relation becomes D.
        //
        // e.g. P' = [ diag(1, 2); 0, 0 ]
        //      ==> G ~= 0 + Z/2 + Z.
        
        let (k, l) = (basis.count, P.cols)
        let E = P.eliminate()
        let Q: Matrix<R, k, k> = E.leftInverse
        
        let newBasis = M.transform(elements: basis, matrix: Q)
        let diag: [R] = E.diagonal
        
        let torPart: [FreeModuleQuotientGenerator]  = diag.enumerated()
            .filter{ (j, a) in a != R.identity }
            .map { (j, a) in .Tor(factor: a, generator: newBasis[j]) }
        
        let freePart: [FreeModuleQuotientGenerator] = (l ..< k).map { j in
            .Free(generator: newBasis[j])
        }
        
        self.init(freePart + torPart)
    }
    
    private static func calculateP<n:_Int, k:_Int, l:_Int>(_ M: Matrix<R, n, k>, _ N: Matrix<R, n, l>) -> Matrix<R, k, l> {
        // With the left-elimination on M as LM = [D; 0], LN = LMP = [DP; 0].
        // LN must be divisible by each diagonal factor of D.
        
        let (k, l) = (M.cols, N.cols)
        
        let L : Matrix<R, n, n> = M.eliminate(mode: .Rows).left
        let D : Matrix<R, k, k> = (L * M).submatrix(rowsInRange: 0 ..< k)
        let DP: Matrix<R, k, l> = (L * N).submatrix(rowsInRange: 0 ..< k)
        
        return  Matrix<R, k, l>(rows: k, cols: l) { (i, j) in
            let a = D[i, i]
            let (q, r) = DP[i, j] /% a
            
            guard r == 0 else {
                fatalError("N is not a submodule of M.")
            }
            
            return q
        }
    }
}
