import Foundation

public struct FreeModuleHom<Key: Hashable, R: Ring>: ModuleHom {
    public typealias M = FreeModule<Key, R>
    public typealias Dom = M
    public typealias Codom = M
    
    public let mapping: [Key : M]
    
    // MEMO: the key is the basis element, 
    // thus is required to be monic.
    public init(_ mapping: [M : M]) {
        self.mapping = mapping.mapPairs{ ($0.bases.first!, $1) }
    }
    
    public func appliedTo(_ m: M) -> M {
        return m.bases.reduce(M.zero) {
            $0 + m.coeff($1) * (mapping[$1] ?? M.zero)
        }
    }
    
    public static var zero: FreeModuleHom<Key, R> {
        return FreeModuleHom([:])
    }
}

public extension FreeModuleHom where R: EuclideanRing {
    private func toMatrix() -> (matrix: TypeLooseMatrix<R>, inBases: [Key], outBases: [Key]) {
        let inBases = Array(mapping.keys)
        let outBases = Array( Set(mapping.values.flatMap { $0.bases }) )
        let A = TypeLooseMatrix<R>(outBases.count, inBases.count) { (i, j) -> R in
            let from = inBases[j]
            let to  = outBases[i]
            return mapping[from]?.coeff(to) ?? 0
        }
        return (A, inBases, outBases)
    }
    
    public func kerIm() -> (Ker: [FreeModule<Key, R>], Im: [FreeModule<Key, R>]) {
        typealias M = FreeModule<Key, R>
        let (A, inBases, outBases) = toMatrix()
        let (kerVecs, imVecs) = SwiftyAlgebra.kerIm(A)
        
        let kers = kerVecs.map{ (v) in
            (0 ..< v.rows).reduce(M.zero){(res, i) in
                res + v[i] * M(inBases[i])
            }
        }
        let ims = imVecs.map{ (v) in
            (0 ..< v.rows).reduce(M.zero){(res, i) in
                res + v[i] * M(outBases[i])
            }
        }
        return (kers, ims)
    }
}
