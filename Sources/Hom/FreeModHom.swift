import Foundation

public struct FreeModuleHom<A: FreeModuleBase, R: Ring>: ModuleHom {
    public typealias M = FreeModule<A, R>
    public typealias Dom = M
    public typealias Codom = M
    
    fileprivate let mapping: [A : M]
    fileprivate let info: FreeModuleHomInfo<A, R>
    
    // MEMO: the key is the basis element
    public init(_ mapping: [A : M]) {
        self.mapping = mapping
        self.info = FreeModuleHomInfo<A, R>()
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
    public var kernelBases : [FreeModule<A, R>] {
        if !info.initialized {
            self.initializeInfo()
        }
        
        return info.kernelBases
    }
    
    public var imageBases : [FreeModule<A, R>] {
        if !info.initialized {
            self.initializeInfo()
        }
        
        return info.imageBases
    }
    
    private func initializeInfo() {
        // TODO sort if possible
        let inBasis = Array(mapping.keys)
        let outBasis = Array( Set(mapping.values.flatMap { $0.basisElements }) )
        let matrix = TypeLooseMatrix<R>(outBasis.count, inBasis.count) { (i, j) -> R in
            let from = inBasis[j]
            let to  = outBasis[i]
            return mapping[from]?.coeff(to) ?? 0
        }
        
        let E = MatrixElimination(matrix)
        
        info.kernelBases = E.kernelVectors.map{ (v) in
            (0 ..< v.rows).reduce(M.zero){(res, i) in
                res + v[i] * M(inBasis[i])
            }
        }
        
        info.imageBases = E.imageVectors.map{ (v) in
            (0 ..< v.rows).reduce(M.zero){(res, i) in
                res + v[i] * M(outBasis[i])
            }
        }
        
        info.initialized = true
    }
}

// boxed class to avoid recomputation of costful functions.
fileprivate class FreeModuleHomInfo<A: FreeModuleBase, R: Ring> {
    var initialized = false
    var kernelBases: [FreeModule<A, R>] = []
    var imageBases: [FreeModule<A, R>] = []
    init() {}
}
