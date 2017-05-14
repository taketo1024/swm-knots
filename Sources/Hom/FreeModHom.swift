import Foundation

public struct FreeModuleHom<A: FreeModuleBase, R: Ring>: ModuleHom {
    public typealias M = FreeModule<A, R>
    public typealias Dom = M
    public typealias Codom = M
    
    public let domainBasis: [A]
    public let codomainBasis: [A]
    public let matrix: TypeLooseMatrix<R>
    
    fileprivate let mapping: [A : M]
    
    // The root initializer
    private init(_ domainBasis: [A], _ codomainBasis: [A], _ matrix: TypeLooseMatrix<R>, _ mapping: [A : M]) {
        self.domainBasis = domainBasis
        self.codomainBasis = codomainBasis
        self.matrix = matrix
        self.mapping = mapping
    }
    
    public init(_ mapping: [A : M]) {
        let domainBasis = Array(mapping.keys)
        let codomainBasis = Array( Set(mapping.values.flatMap { $0.basis }) )
        self.init(domainBasis: domainBasis, codomainBasis: codomainBasis, mapping: mapping)
    }
    
    public init(domainBasis: [A], codomainBasis: [A], mapping: [A : M]) {
        let matrix = FreeModuleHom.map2matrix(domainBasis, codomainBasis, mapping)
        self.init(domainBasis, codomainBasis, matrix, mapping)
    }
    
    public init(domainBasis: [A], codomainBasis: [A], matrix: TypeLooseMatrix<R>) {
        let mapping = FreeModuleHom.matrix2map(domainBasis, codomainBasis, matrix)
        self.init(domainBasis, codomainBasis, matrix, mapping)
    }
    
    public static var zero: FreeModuleHom<A, R> {
        return FreeModuleHom([:])
    }
    
    public func appliedTo(_ m: M) -> M {
        return m.basis.reduce(M.zero) {
            $0 + m.coeff($1) * (mapping[$1] ?? M.zero)
        }
    }
    
    private static func map2matrix(_ domainBasis: [A], _ codomainBasis: [A], _ mapping: [A : M]) -> TypeLooseMatrix<R> {
        return TypeLooseMatrix<R>(codomainBasis.count, domainBasis.count) { (i, j) -> R in
            let from = domainBasis[j]
            let to  = codomainBasis[i]
            return mapping[from]?.coeff(to) ?? 0
        }
    }
    
    private static func matrix2map<n: _Int, m: _Int>(_ domainBasis: [A], _ codomainBasis: [A], _ matrix: Matrix<R, n, m>) -> [A : M] {
        
        let codomainBasisM = codomainBasis.map {M($0)}
        let pairs: [(A, M)] = domainBasis.enumerated().map{ (j, a) in
            (a, codomainBasisM.enumerated().reduce(M.zero) { (res, enm) in
                let (i, m) = enm
                return res + m * matrix[i, j]
            })
        }
        return Dictionary(pairs)
    }
}

// MEMO this implementation is not good. improve if there is a better way.
public extension FreeModuleHom where R: EuclideanRing {
    public var kernelRank: Int {
        return matrix.rankNormalElimination.nullity
    }
    
    public var kernelGenerators: [M] {
        return matrix.rankNormalElimination.kernelVectors.map{ M(basis: domainBasis, values: $0.colArray(0)) }
    }
    
    public var imageRank: Int {
        return matrix.rankNormalElimination.rank
    }
    
    public var imageGenerators: [M] {
        return matrix.rankNormalElimination.imageVectors.map{ M(basis: codomainBasis, values: $0.colArray(0)) }
    }
}
