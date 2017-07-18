import Foundation

public struct FreeModuleHom<A: FreeModuleBase, R: Ring>: ModuleHom {
    public typealias M = FreeModule<A, R>
    public typealias Dom = M
    public typealias Codom = M
    
    public typealias Basis = [A]
    
    public let domainBasis: Basis
    public let codomainBasis: Basis
    public let matrix: DynamicMatrix<R>
    
    // The root initializer
    public init(domainBasis: Basis, codomainBasis: Basis, matrix: DynamicMatrix<R>) {
        self.domainBasis = domainBasis
        self.codomainBasis = codomainBasis
        self.matrix = matrix
    }
    
    public init(domainBasis: Basis, codomainBasis: Basis, mapping: [R]) {
        self.init(domainBasis: domainBasis,
                  codomainBasis: codomainBasis,
                  matrix: DynamicMatrix(rows: codomainBasis.count, cols: domainBasis.count, grid: mapping))
    }
    
    public static var zero: FreeModuleHom<A, R> {
        return FreeModuleHom(domainBasis: [], codomainBasis: [], mapping: [])
    }
    
    public func appliedTo(_ m: M) -> M {
        let comps = (0 ..< codomainBasis.count).map{ i -> R in
            (0 ..< domainBasis.count).reduce(R.zero){ (res, j) -> R in
                res + m.component(forBasisElement: domainBasis[j]) * matrix[i, j]
            }
        }
        return M(basis: codomainBasis, components: comps)
    }
    
    private static func map2matrix(_ domainBasis: Basis, _ codomainBasis: Basis, _ mapping: [A : M]) -> DynamicMatrix<R> {
        return DynamicMatrix<R>(rows: codomainBasis.count, cols: domainBasis.count) { (i, j) -> R in
            let from = domainBasis[j]
            let to  = codomainBasis[i]
            return mapping[from]?.component(forBasisElement: to) ?? 0
        }
    }
}
