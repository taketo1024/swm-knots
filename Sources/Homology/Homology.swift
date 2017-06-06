//
//  Homology.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias Homology<A: FreeModuleBase, R: EuclideanRing> = BaseHomology<DescendingChainType, A, R>
public typealias Cohomology<A: FreeModuleBase, R: EuclideanRing> = BaseHomology<AscendingChainType, A, R>

public struct BaseHomology<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: CustomStringConvertible {
    public let chainComplex: BaseChainComplex<chainType, A, R>
    public let groups: [HomologyGroupInfo<chainType, A, R>]
    
    public init(chainComplex: BaseChainComplex<chainType, A, R>, groups: [HomologyGroupInfo<chainType, A, R>]) {
        self.chainComplex = chainComplex
        self.groups = groups
    }
    
    public init(_ chainComplex: BaseChainComplex<chainType, A, R>) {
        typealias  M = FreeModule<A, R>
        
        let descending = (chainType.self == DescendingChainType.self)
        let dim = chainComplex.dim
        let elims = chainComplex.boundaryMaps.map { $0.matrix.eliminate() }
        
        let groups = (0 ... dim).map { (i) -> HomologyGroupInfo<chainType, A, R> in
            // Basis of C_i : the i-th Chain group
            let basis = chainComplex.boundaryMaps[i].domainBasis
            
            // Z_i : the i-th Cycle group
            let A = elims[i]
            let Z = A.kernelPart       // PAQ = [D; O_k]  =>  Z = Q * [O; I_k]
            
            // B_i : the i-th Boundary group
            let j = (descending) ? (i + 1) : (i - 1)
            let B = (0 <= j && j < elims.count) ? elims[j].imagePart : DynamicMatrix(rows: basis.count, cols: 0, grid:[])
            
            // C_i -> Z_i transition matrix
            let (n, k) = (Z.rows, Z.cols)
            let Qinv = A.rightInverse  // Q^-1 * Z = [O; I_k]
            let T: DynamicMatrix<R> = Qinv.submatrix(rowsInRange: n - k ..< n) // T * Z = I_k
            
            return HomologyGroupInfo(basis: basis, cycleMatrix: Z, boundaryMatrix: B, chain2cycleMatrix: T)
        }
        
        self.init(chainComplex: chainComplex, groups: groups)
    }
    
    public var description: String {
        return "{" + groups.enumerated().map{"\($0):\($1)"}.joined(separator: ", ") + "}"
    }
    
    public var detailDescription: String {
        return "{\n"
            + groups.enumerated().map{"\t\($0) : \($1),\t\($1.generators.map{$0.generator})"}.joined(separator: ",\n")
            + "\n}"
    }
}

public extension BaseHomology where chainType == DescendingChainType, R == IntegerNumber {
    public func bettiNumer(i: Int) -> Int {
        return groups[i].generators.filter{ $0.isFree }.count
    }
    
    public var eulerCharacteristic: Int {
        return (0 ... chainComplex.dim).reduce(0){ $0 + (($1 % 2 == 0) ? 1 : -1) * bettiNumer(i: $1) }
    }
}

public class HomologyGroupInfo<chainType: ChainType, A: FreeModuleBase, R: EuclideanRing>: TypeInfo {
    public enum Generator: CustomStringConvertible {
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
    
    public let rank: Int
    public let torsions: Int
    
    public let generators: [Generator]
    public let chainBasis: [A]
    public let transitionMatrix: DynamicMatrix<R> // chain -> cycle
    
    private typealias M = FreeModule<A, R>
    
    public init(basis: [A], cycleMatrix Z: DynamicMatrix<R>, boundaryMatrix B: DynamicMatrix<R>, chain2cycleMatrix T: DynamicMatrix<R>) {
        let (k, l) = (Z.cols, B.cols)
        let (newBasis, newTrans, diagonal) = HomologyGroupInfo.calculate(basis, Z, B, T)
        
        let torPart: [Generator]  = diagonal.enumerated()
            .filter{ (j, a) in a != R.identity }
            .map { (j, a) in .Tor(factor: a, generator: newBasis[j]) }
        
        let freePart: [Generator] = (l ..< k).map { j in
            .Free(generator: newBasis[j])
        }
        
        self.rank = freePart.count
        self.torsions = torPart.count
        
        self.generators = (freePart + torPart)
        self.chainBasis = basis
        self.transitionMatrix = newTrans
    }
    
    // Calculate with size-typed matrices.
    private static func calculate<n:_Int, k:_Int, l:_Int>(_ basis: [A], _ Z: Matrix<R, n, k>, _ B: Matrix<R, n, l>, _ T: Matrix<R, k, n>) -> (newBasis: [M],  transitionMatrix: Matrix<R, k, n>, diagonal: [R]) {
        
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
    
    public func components(_ z: FreeModule<A, R>) -> [R] {
        let chainComps = z.components(forBasis: chainBasis)
        let cycleComps = (transitionMatrix * DynamicMatrix(chainComps.count, 1, chainComps)).colArray(0)
        
        let k = cycleComps.count // k = (null-part) + (tor-part) + (free-part)
        
        let freeVals = (0 ..< rank).map{ i in cycleComps[(k - rank) + i] }
        let torVals  = (0 ..< torsions).map{ (i) -> R in
            if case .Tor(let r, _) = generators[rank + i] {
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
        let desc = generators.map{$0.description}.joined(separator: "⊕")
        return desc.isEmpty ? "0" : desc
    }
}

public protocol _HomologyGroup: _QuotientModule {
    associatedtype chainType: ChainType
    associatedtype A: FreeModuleBase
    associatedtype R: EuclideanRing
    
    var representative: FreeModule<A, R> { get }
    init(_ z: FreeModule<A, R>)
    
    static var info: HomologyGroupInfo<chainType, A, R> { get }
}

public extension _HomologyGroup where Base == FreeModule<A, R>{
    public static func isEquivalent (a: Base, b: Base) -> Bool {
        return info.isHomologue(a, b)
    }
    
    public var hashValue: Int {
        return (Self.info.isNullHomologue(representative)) ? 0 : 1
    }
    
    public static var symbol: String {
        return info.description
    }
}

public struct DynamicHomologyGroup<_chainType: ChainType, _A: FreeModuleBase, _R: EuclideanRing, _ID: _Int>: DynamicType, _HomologyGroup {
    public typealias chainType = _chainType
    public typealias A = _A
    public typealias R = _R
    public typealias Base = FreeModule<A, R>
    public typealias Sub  = FreeZeroModule<A, R> // used as stub
    public typealias Info = HomologyGroupInfo<chainType, A, R>
    public typealias ID = _ID
    
    private let z: FreeModule<A, R>
    public init(_ z: FreeModule<A, R>) {
        // TODO check if z is a cycle.
        self.z = z
    }
    
    public var representative: FreeModule<A, R> {
        return z
    }
}
