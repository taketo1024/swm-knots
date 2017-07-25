//
//  HomologyGroupInfo.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/18.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public class HomologyGroupInfo<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: TypeInfo {
    public typealias ChainBasis = [A]
    
    public enum Summand: CustomStringConvertible {
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
    
    public let degree: Int
    public let chainBasis: ChainBasis
    
    public let rank: Int
    public let torsions: Int
    
    public let summands: [Summand]
    public let transitionMatrix: DynamicMatrix<R> // chain -> cycle
    
    private typealias M = FreeModule<A, R>
    
    public convenience init(_ chainComplex: _ChainComplex<chainType, A, R>, degree: Int) {
        let d1 = chainComplex.boundaryMap(degree)
        let d2 = chainComplex.boundaryMap(chainComplex.descending ? degree + 1 : degree - 1)
        let basis = d1.domainBasis
        let E1 = d1.matrix.eliminate()
        let E2 = d2.matrix.eliminate()
        
        self.init(degree: degree, basis: basis, elim1: E1, elim2: E2)
    }
    
    internal init<n0: _Int, n1: _Int, n2: _Int>(degree: Int, basis: ChainBasis, elim1 E1: MatrixElimination<R, n0, n1>, elim2 E2: MatrixElimination<R, n1, n2>) {
        // Z_i : the i-th Cycle group
        let Z = E1.kernelPart
        let (n, k) = (Z.rows, Z.cols)
        
        // B_i : the i-th Boundary group
        let B = E2.imagePart
        let l = B.cols
        
        // C_i -> Z_i transition matrix
        //   PAQ = [D; O_k]  =>  Z = Q * [O; I_k]
        //   Q^-1 * Z = [O; I_k]
        let Qinv = E1.rightInverse
        let T: Matrix<R, Dynamic, n1> = Qinv.submatrix(rowsInRange: n - k ..< n) // T * Z = I_k
        
        let (newBasis, newTrans, diagonal) = HomologyGroupInfo.calculate(basis, Z, B, T)
        
        let torPart: [Summand]  = diagonal.enumerated()
            .filter{ (j, a) in a != R.identity }
            .map { (j, a) in .Tor(factor: a, generator: newBasis[j]) }
        
        let freePart: [Summand] = (l ..< k).map { j in
            .Free(generator: newBasis[j])
        }
        
        self.degree = degree
        self.chainBasis = basis
        
        self.rank = freePart.count
        self.torsions = torPart.count
        
        self.summands = (freePart + torPart)
        self.transitionMatrix = newTrans.asDynamic
    }
    
    // Calculate with size-typed matrices.
    private static func calculate<n:_Int, k:_Int, l:_Int>(_ basis: ChainBasis, _ Z: Matrix<R, n, k>, _ B: Matrix<R, n, l>, _ T: Matrix<R, k, n>) -> (newBasis: [M],  transitionMatrix: Matrix<R, k, n>, diagonal: [R]) {
        
        // Find R such that B = Z * P.
        // Since T * Z = I_k,  T * B = P.
        
        let P: Matrix<R, k, l> = T * B
        
        // Eliminate P as S * P * U = [D; 0].
        // By taking basis * Z * S^-1 as a new basis of the cycle group, the relation becomes D.
        // The new transition matrix is given by S * T.
        //
        // e.g. P' = [ diag(1, 2); 0, 0 ]
        //      ==> G ~= 0 + Z/2 + Z.
        
        let E = P.eliminate()
        
        let newBasis = M.generateElements(basis: basis, matrix: Z * E.leftInverse)
        let newTrans: Matrix<R, k, n> = E.left * T
        let diagonal: [R] = E.diagonal
        
        return (newBasis, newTrans, diagonal)
    }
    
    public func generator(_ i: Int) -> FreeModule<A, R> {
        return summands[i].generator
    }
    
    public func components(_ z: FreeModule<A, R>) -> [R] {
        let chainComps = z.components(correspondingTo: chainBasis)
        let cycleComps = (transitionMatrix * ColVector(rows: chainComps.count, grid: chainComps)).colArray(0)
        
        let k = cycleComps.count // k = (null-part) + (tor-part) + (free-part)
        
        let freeVals = (0 ..< rank).map{ i in cycleComps[(k - rank) + i] }
        let torVals  = (0 ..< torsions).map{ (i) -> R in
            if case .Tor(let r, _) = summands[rank + i] {
                return cycleComps[(k - rank - torsions) + i] % r
            } else {
                fatalError("something is wrong.")
            }
        }
        return freeVals + torVals
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
}
