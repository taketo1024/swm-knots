import Foundation

public struct FreeModuleHom<A: FreeModuleBase, R: Ring>: ModuleHom {
    public typealias M = FreeModule<A, R>
    public typealias Dom = M
    public typealias Codom = M
    
    public let mapping: [A : M]
    
    public let inBasis: [A]
    public let outBasis: [A]
    public let matrix: TypeLooseMatrix<R>
    
    // MEMO: the key is the basis element
    public init(_ mapping: [A : M]) {
        self.mapping = mapping
        
        // TODO sort if possible
        self.inBasis = Array(mapping.keys)
        self.outBasis = Array( Set(mapping.values.flatMap { $0.basisElements }) )
        self.matrix = FreeModuleHom.toMatrix(mapping, inBasis, outBasis)
    }
    
    public func appliedTo(_ m: M) -> M {
        return m.basisElements.reduce(M.zero) {
            $0 + m.coeff($1) * (mapping[$1] ?? M.zero)
        }
    }
    
    public static var zero: FreeModuleHom<A, R> {
        return FreeModuleHom([:])
    }
    
    private static func toMatrix(_ mapping: [A : M], _ inBasis: [A], _ outBasis: [A]) -> TypeLooseMatrix<R> {
        return TypeLooseMatrix<R>(outBasis.count, inBasis.count) { (i, j) -> R in
            let from = inBasis[j]
            let to  = outBasis[i]
            return mapping[from]?.coeff(to) ?? 0
        }
    }
}

// TODO store to avoid recomputing.
public extension FreeModuleHom where R: EuclideanRing {
    public func kerIm() -> (Ker: [FreeModule<A, R>], Im: [FreeModule<A, R>]) {
        typealias M = FreeModule<A, R>
        let (kerVecs, imVecs) = SwiftyAlgebra.kerIm(matrix)
        
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
