import Foundation

public struct FreeModuleHom<A: FreeModuleBase, R: Ring>: ModuleHom {
    public typealias M = FreeModule<A, R>
    public typealias Dom = M
    public typealias Codom = M
    
    public let domainBasis: [A]
    public let codomainBasis: [A]
    public let matrix: TypeLooseMatrix<R>
    
    // The root initializer
    public init(domainBasis: [A], codomainBasis: [A], matrix: TypeLooseMatrix<R>) {
        self.domainBasis = domainBasis
        self.codomainBasis = codomainBasis
        self.matrix = matrix
    }
    
    public init(domainBasis: [A], codomainBasis: [A], mapping: [R]) {
        self.init(domainBasis: domainBasis,
                  codomainBasis: codomainBasis,
                  matrix: TypeLooseMatrix(rows: codomainBasis.count, cols: domainBasis.count, grid: mapping))
    }
    
    public static var zero: FreeModuleHom<A, R> {
        return FreeModuleHom(domainBasis: [], codomainBasis: [], mapping: [])
    }
    
    public func appliedTo(_ m: M) -> M {
        let values = (0 ..< codomainBasis.count).map{ i -> R in
            (0 ..< domainBasis.count).reduce(R.zero){ (res, j) -> R in
                res + m.value(forBasisElement: domainBasis[j]) * matrix[i, j]
            }
        }
        return M(basis: codomainBasis, values: values)
    }
    
    private static func map2matrix(_ domainBasis: [A], _ codomainBasis: [A], _ mapping: [A : M]) -> TypeLooseMatrix<R> {
        return TypeLooseMatrix<R>(codomainBasis.count, domainBasis.count) { (i, j) -> R in
            let from = domainBasis[j]
            let to  = codomainBasis[i]
            return mapping[from]?.value(forBasisElement: to) ?? 0
        }
    }
}
