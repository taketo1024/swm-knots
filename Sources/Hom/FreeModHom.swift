import Foundation

public struct FreeModuleHom<A: FreeModuleBase, R: Ring>: ModuleHom {
    public typealias M = FreeModule<A, R>
    public typealias Dom = M
    public typealias Codom = M
    
    public let domainBasis: [A]
    public let codomainBasis: [A]
    
    // TODO might rather keep the matrix than this table.
    
    fileprivate let mapping: [A : M]
    fileprivate let _info: FreeModuleHomInfo<A, R>
    
    public init(_ mapping: [A : M]) {
        // TODO sort if possible
        let domainBasis = Array(mapping.keys)
        let codomainBasis = Array( Set(mapping.values.flatMap { $0.basis }) )
        // --TODO
        
        self.init(domainBasis: domainBasis, codomainBasis: codomainBasis, mapping: mapping)
    }
    
    public init(domainBasis: [A], codomainBasis: [A], mapping: [A : M]) {
        self.domainBasis = domainBasis
        self.codomainBasis = codomainBasis
        self.mapping = mapping
        self._info = FreeModuleHomInfo<A, R>()
    }
    
    public init<n: _Int, m: _Int>(domainBasis: [A], codomainBasis: [A], matrix m: Matrix<R, n, m>) {
        let codomainBasisM = codomainBasis.map {M($0)}
        let mapping = Dictionary(
            domainBasis.enumerated().map{ (j, a) in
                (a, codomainBasisM.enumerated().reduce(M.zero) { (res, enm) in
                    res + enm.1 * m[enm.0, j]
                })
        })
        self.init(domainBasis: domainBasis, codomainBasis: codomainBasis, mapping: mapping)
    }
    
    public static var zero: FreeModuleHom<A, R> {
        return FreeModuleHom([:])
    }
    
    public func appliedTo(_ m: M) -> M {
        return m.basis.reduce(M.zero) {
            $0 + m.coeff($1) * (mapping[$1] ?? M.zero)
        }
    }
}

// MEMO this implementation is not good. improve if there is a better way.
public extension FreeModuleHom where R: EuclideanRing {
    public var kernelGenerators: [M] {
        return elimination.kernelVectors.map{ M(basis: domainBasis, values: $0.colArray(0)) }
    }
    
    public var imageGenerators: [M] {
        return elimination.imageVectors.map{ M(basis: codomainBasis, values: $0.colArray(0)) }
    }
    
    internal var elimination: MatrixElimination<R, _TypeLooseSize, _TypeLooseSize> {
        return info.elimination as! MatrixElimination<R, _TypeLooseSize, _TypeLooseSize>
    }
    
    internal var info: FreeModuleHomInfo<A, R> {
        if !_info.initialized {
            self.initializeInfo()
        }
        
        return _info
    }
    
    private func initializeInfo() {
        let info = _info
        
        let matrix = TypeLooseMatrix<R>(codomainBasis.count, domainBasis.count) { (i, j) -> R in
            let from = domainBasis[j]
            let to  = codomainBasis[i]
            return mapping[from]?.coeff(to) ?? 0
        }
        
        info.elimination = MatrixElimination(matrix)
        info.initialized = true
    }
}

// boxed class to avoid recomputation of costful functions.
internal class FreeModuleHomInfo<A: FreeModuleBase, R: Ring> {
    typealias M = FreeModule<A, R>
    fileprivate var initialized = false
    
    var elimination: Any!
    
    init() {}
}
