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
    
    public init<n: _Int, k:_Int, l:_Int>(basis: [A], generator S: Matrix<R, n, k>, relation P: Matrix<R, k, l>) {
        
        // Eliminate P as QPR = [D; 0].
        // By taking basis * Q^-1 as a new basis, the relation becomes D.
        //
        // e.g. P' = [ diag(1, 2); 0, 0 ]
        //      ==> G ~= 0 + Z/2 + Z.
        
        let (k, l) = (S.cols, P.cols)
        let E = P.eliminate()
        
        let newBasis = basis.generateElements(by: S * E.leftInverse)
        let diag: [R] = E.diagonal
        
        let torPart: [FreeModuleQuotientGenerator]  = diag.enumerated()
            .filter{ (j, a) in a != R.identity }
            .map { (j, a) in .Tor(factor: a, generator: newBasis[j]) }
        
        let freePart: [FreeModuleQuotientGenerator] = (l ..< k).map { j in
            .Free(generator: newBasis[j])
        }
        
        self.init(freePart + torPart)
    }
}
