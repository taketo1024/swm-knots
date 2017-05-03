import Foundation

public struct FreeModuleHom<R: Ring>: ModuleHom {
    public typealias M = FreeModule<R>
    public typealias Dom = M
    public typealias Codom = M
    
    public let mapping: [String : M]
    
    public init(_ mapping: [M : M]) {
        self.mapping = mapping.mapPairs{($0.name, $1)}
    }
    
    public func appliedTo(_ m: M) -> M {
        return m.bases.reduce(M.zero) {
            $0 + m.coeff($1) * (mapping[$1] ?? M.zero)
        }
    }
}

public extension FreeModuleHom where R: EuclideanRing {
    private func toMatrix() -> (matrix: TypeLooseMatrix<R>, inBases: [String], outBases: [String]) {
        let inBases = Array(mapping.keys).sorted()
        let outBases = Array(Set(mapping.values.flatMap { $0.bases })).sorted()
        let A = TypeLooseMatrix<R>(outBases.count, inBases.count) { (i, j) -> R in
            let from = inBases[j]
            let to  = outBases[i]
            return mapping[from]?.coeff(to) ?? 0
        }
        return (A, inBases, outBases)
    }
    
    public func kerIm() -> (Ker: [FreeModule<R>], Im: [FreeModule<R>]) {
        typealias M = FreeModule<R>
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
