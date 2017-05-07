import Foundation

public struct FreeModuleHom<A: Hashable, R: Ring>: ModuleHom {
    public typealias M = FreeModule<A, R>
    public typealias Dom = M
    public typealias Codom = M
    
    public let mapping: [A : M]
    
    // MEMO: the key is the basis element, 
    // thus is required to be monic.
    public init(_ mapping: [A : M]) {
        self.mapping = mapping
    }
    
    public func appliedTo(_ m: M) -> M {
        return m.basisElements.reduce(M.zero) {
            $0 + m.coeff($1) * (mapping[$1] ?? M.zero)
        }
    }
    
    public static var zero: FreeModuleHom<A, R> {
        return FreeModuleHom([:])
    }
}

public extension FreeModuleHom where R: EuclideanRing {
    private func toMatrix() -> (matrix: TypeLooseMatrix<R>, inBases: [A], outBases: [A]) {
        let inBasis = Array(mapping.keys)
        let outBasis = Array( Set(mapping.values.flatMap { $0.basisElements }) )
        let A = TypeLooseMatrix<R>(outBasis.count, inBasis.count) { (i, j) -> R in
            let from = inBasis[j]
            let to  = outBasis[i]
            return mapping[from]?.coeff(to) ?? 0
        }
        return (A, inBasis, outBasis)
    }
    
    public func kerIm() -> (Ker: [FreeModule<A, R>], Im: [FreeModule<A, R>]) {
        typealias M = FreeModule<A, R>
        let (A, inBasis, outBasis) = toMatrix()
        let (kerVecs, imVecs) = SwiftyAlgebra.kerIm(A)
        
        let kers = kerVecs.map{ (v) in
            (0 ..< v.rows).reduce(M.zero){(res, i) in
                res + v[i] * M(inBasis[i])
            }
        }
        let ims = imVecs.map{ (v) in
            (0 ..< v.rows).reduce(M.zero){(res, i) in
                res + v[i] * M(outBasis[i])
            }
        }
        return (kers, ims)
    }
}
