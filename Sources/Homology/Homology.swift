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
    internal let groupInfos: [HomologyGroupInfo<chainType, A, R>]
    
    public subscript(i: Int) -> HomologyGroupInfo<chainType, A, R> {
        return groupInfos[i]
    }
    
    public init(chainComplex: BaseChainComplex<chainType, A, R>, groups: [HomologyGroupInfo<chainType, A, R>]) {
        self.chainComplex = chainComplex
        self.groupInfos = groups
    }
    
    public init(_ chainComplex: BaseChainComplex<chainType, A, R>) {
        typealias M = FreeModule<A, R>
        
        let offset = chainComplex.offset
        let dim    = chainComplex.dim
        
        let elims = { () -> (Int) -> MatrixElimination<R, Dynamic, Dynamic> in
            let res = (offset - 1 ... dim + 1).map { chainComplex.boundaryMap($0).matrix.eliminate() }
            return { (i: Int) -> MatrixElimination<R, Dynamic, Dynamic> in
                return res[i - offset + 1]
            }
        }()
        
        let groups = (offset ... dim).map { (i) -> HomologyGroupInfo<chainType, A, R> in
            HomologyGroupInfo(dim: i,
                              basis: chainComplex.chainBasis(i),
                              elim1: elims(i),
                              elim2: chainComplex.descending ? elims(i + 1) : elims(i - 1))
        }
        
        self.init(chainComplex: chainComplex, groups: groups)
    }
    
    public var description: String {
        return "{" + groupInfos.map{"\($0.dim):\($0)"}.joined(separator: ", ") + "}"
    }
    
    public var detailDescription: String {
        return "{\n"
            + groupInfos.map{"\t\($0.dim) : \($0.detailDescription)"}.joined(separator: ",\n")
            + "\n}"
    }
}

public extension BaseHomology where chainType == DescendingChainType, R == IntegerNumber {
    public func bettiNumer(i: Int) -> Int {
        return groupInfos[i].summands.filter{ $0.isFree }.count
    }
    
    public var eulerCharacteristic: Int {
        return (0 ... chainComplex.dim).reduce(0){ $0 + (($1 % 2 == 0) ? 1 : -1) * bettiNumer(i: $1) }
    }
}

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
    
    public let dim: Int
    public let chainBasis: ChainBasis
    
    public let rank: Int
    public let torsions: Int
    
    public let summands: [Summand]
    public let transitionMatrix: DynamicMatrix<R> // chain -> cycle
    
    private typealias M = FreeModule<A, R>
    
    public convenience init(dim: Int, boundaryMap: FreeModuleHom<A, R>, preboundaryMap: FreeModuleHom<A, R>) {
        assert(boundaryMap.domainBasis == preboundaryMap.codomainBasis)
        
        let basis = boundaryMap.domainBasis
        let E1 = boundaryMap.matrix.eliminate()
        let E2 = preboundaryMap.matrix.eliminate()
        
        self.init(dim: dim, basis: basis, elim1: E1, elim2: E2)
    }
    
    internal init<n0: _Int, n1: _Int, n2: _Int>(dim: Int, basis: ChainBasis, elim1 E1: MatrixElimination<R, n0, n1>, elim2 E2: MatrixElimination<R, n1, n2>) {
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
        
        self.dim = dim
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
        let chainComps = z.components(forBasis: chainBasis)
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

public protocol _HomologyGroup: _QuotientModule {
    associatedtype chainType: ChainType
    associatedtype A: FreeModuleBase
    associatedtype R: EuclideanRing
    
    var representative: FreeModule<A, R> { get }
    init(_ z: FreeModule<A, R>)
    
    static var dim: Int { get }
    static func generator(_ i: Int) -> Self
    static var info: HomologyGroupInfo<chainType, A, R> { get }
}

public extension _HomologyGroup where Base == FreeModule<A, R> {
    public static var dim: Int {
        return info.dim
    }
    
    public static func generator(_ i: Int) -> Self {
        return Self.init(info.generator(i))
    }
    
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

public extension _HomologyGroup where Base == FreeModule<A, R>, chainType == AscendingChainType {
    public static func * <H: _HomologyGroup>(a: Self, b: H) -> R where Self.A == H.A, Self.R == H.R, H.chainType == DescendingChainType {
        assert(Self.info.dim == H.info.dim)
        let x = a.representative
        let y = b.representative
        let basis = (x.basis + y.basis).unique()
        return basis.reduce(R.zero) { (sum, e) in sum + x.component(forBasisElement: e) * y.component(forBasisElement: e) }
    }
    
    public static func * <H: _HomologyGroup>(b: H, a: Self) -> R where Self.A == H.A, Self.R == H.R, H.chainType == DescendingChainType {
        return a * b
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
