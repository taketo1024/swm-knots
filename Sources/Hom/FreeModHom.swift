import Foundation

public struct FreeModuleHom<A: FreeModuleBase, R: Ring>: ModuleHom {
    public typealias M = FreeModule<A, R>
    public typealias Dom = M
    public typealias Codom = M
    
    let inBasis: [A]
    let outBasis: [A]
    fileprivate let mapping: [A : M]
    fileprivate let _info: FreeModuleHomInfo<A, R>
    
    public init(_ mapping: [A : M]) {
        // TODO sort if possible
        let inBasis = Array(mapping.keys)
        let outBasis = Array( Set(mapping.values.flatMap { $0.basisElements }) )
        // --TODO
        
        self.init(inBasis: inBasis, outBasis: outBasis, mapping: mapping)
    }
    
    public init(inBasis: [A], outBasis: [A], mapping: [A : M]) {
        self.inBasis = inBasis
        self.outBasis = outBasis
        self.mapping = mapping
        self._info = FreeModuleHomInfo<A, R>()
    }
    
    public static var zero: FreeModuleHom<A, R> {
        return FreeModuleHom([:])
    }
    
    public func appliedTo(_ m: M) -> M {
        return m.basisElements.reduce(M.zero) {
            $0 + m.coeff($1) * (mapping[$1] ?? M.zero)
        }
    }
}

// MEMO this implementation is not good. improve if there is a better way.
public extension FreeModuleHom where R: EuclideanRing {
    public var kernel: [M] {
        return elimination.kernelVectors.map{ M.vec2El($0, basis: inBasis) }
    }
    
    public var image: [M] {
        return elimination.imageVectors.map{ M.vec2El($0, basis: outBasis) }
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
        
        let matrix = TypeLooseMatrix<R>(outBasis.count, inBasis.count) { (i, j) -> R in
            let from = inBasis[j]
            let to  = outBasis[i]
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
