//
//  Homology.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

// TODO maybe create a generic "FreeModuleQuotient" type.
public enum HomologyGrouopGenerator<A: FreeModuleBase, R: Ring>: CustomStringConvertible {
    case Free(generator: FreeModule<A, R>)
    case Tor(factor: R, generator: FreeModule<A, R>)
    
    public var description: String {
        let name = (R.self == IntegerNumber.self) ? "Z" : "\(R.self)"
        switch self{
        case .Free(_): return name
        case let .Tor(_, f): return "\(name)/\(f)"
        }
    }
}

public struct HomologyGroup<A: FreeModuleBase, R: Ring>: CustomStringConvertible {
    public let dim: Int
    public let generators: [HomologyGrouopGenerator<A, R>]
    
    public init(dim: Int, generators: [HomologyGrouopGenerator<A, R>]) {
        self.dim = dim
        self.generators = generators
    }
    
    public var description: String {
        let desc = generators.map{$0.description}.joined(separator: "⊕")
        return desc.isEmpty ? "0" : desc
    }
}

public extension HomologyGroup where R: EuclideanRing {
    public init(dim i: Int, chainComplex: ChainComplex<A, R>) {
        typealias M = FreeModule<A, R>
        
        let d0 = chainComplex.boundaryMap(i)
        let d1 = chainComplex.boundaryMap(i + 1)
        let basis = d0.inBasis
        
        let K = d0.elimination.kernelPart // cycles = basis * K
        let L = d1.elimination.imagePart  // bnds   = basis * L
        let k = K.cols // number of cycles
        let l = L.cols // number of bnds
        
        // We represent imgs by a combination of kers.
        // If L = KP, bnds = basis * KP = cycles * P.
        // Thus each bnd can be expressed as a combination of cycles.
        //
        // To compute P, by eliminating K as Q * K = [I_k; 0],
        // we obtain Q * L = Q * K * P = [P; 0].
        
        let Q = MatrixElimination(K, mode: .RowsOnly).left
        let P = (Q * L).submatrix(rowsInRange: 0 ..< k)
        
        // Now let P' = SPT, where P' = [D_l; 0].
        //
        //   bnds * T = cycles * PT
        //            = cycles * (S^-1 P')
        //            = basis * (K S^-1) P'
        //
        // The gens of H_i can be computed by T = K S^-1
        //
        // ex) R' = [ diag(1, 1, 2); 0_3 ] => H_i = 0 + 0 + Z/Z2 + Z^3.
        
        let E = MatrixElimination(P)
        let T = K * E.leftInverse
        
        
        let freePart: [HomologyGrouopGenerator] = (l ..< k).map { j in
            .Free(generator: M(basis: basis, values: T.colVector(j)))
        }
        
        let torPart: [HomologyGrouopGenerator]  = E.diagonal.enumerated()
            .filter{ (j, a) in a != R.identity }
            .map { (j, a) in
                .Tor(factor: a, generator: M(basis: basis, values: T.colVector(j)))
        }
        
        self.init(dim: i, generators: freePart + torPart)
    }
}

public struct Homology<A: FreeModuleBase, R: Ring>: CustomStringConvertible {
    public let chainComplex: ChainComplex<A, R>
    public let groups: [HomologyGroup<A, R>]
    
    public init(_ chainComplex: ChainComplex<A, R>) {
        self.chainComplex = chainComplex
        self.groups = []
    }
    
    public var description: String {
        return "{" + groups.map{"\($0.dim):\($0)"}.joined(separator: ", ") + "}"
    }
}

fileprivate extension FreeModule {
    init<n: _Int>(basis: [A], values: ColVector<R, n>) {
        guard basis.count == values.rows else {
            fatalError("#basis (\(basis.count)) != #values (\(values.rows))")
        }
        let pairs = basis.enumerated().map { (i, a) in (a, values[i]) }
        self.init( Dictionary(pairs) )
    }
    
    static func generate<n: _Int, m: _Int>(basis: [A], matrix: Matrix<R, n, m>) -> [FreeModule<A, R>] {
        return (0 ..< matrix.cols).map{ matrix.colVector($0) }.map{ FreeModule<A, R>(basis: basis, values: $0) }
    }
}

public extension Homology where R: EuclideanRing {
    public init(_ chainComplex: ChainComplex<A, R>) {
        self.chainComplex = chainComplex
        self.groups = (0 ... chainComplex.dim).map{ HomologyGroup(dim: $0, chainComplex: chainComplex) }
    }
}
