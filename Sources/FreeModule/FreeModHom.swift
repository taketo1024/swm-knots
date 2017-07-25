import Foundation

public struct FreeModuleHom<A: FreeModuleBase, _R: Ring>: ModuleHom {
    public typealias R = _R
    public typealias M = FreeModule<A, R>
    public typealias Dom = M
    public typealias Codom = M
    
    public typealias Basis = [A]
    
    public let domainBasis: Basis
    public let codomainBasis: Basis
    public let matrix: DynamicMatrix<R>
    
    // The root initializer
    public init<n: _Int, m: _Int>(domainBasis: Basis, codomainBasis: Basis, matrix: Matrix<R, n, m>) {
        self.domainBasis = domainBasis
        self.codomainBasis = codomainBasis
        self.matrix = matrix.asDynamic
    }
    
    public static var zero: FreeModuleHom<A, R> {
        return FreeModuleHom(domainBasis: [], codomainBasis: [], matrix: Matrix<R, _0, _0>.zero)
    }
    
    // TODO very slow
    public func appliedTo(_ m: M) -> M {
        let comps = (0 ..< codomainBasis.count).map{ i -> R in
            (0 ..< domainBasis.count).reduce(R.zero){ (res, j) -> R in
                res + m[domainBasis[j]] * matrix[i, j]
            }
        }
        return M(basis: codomainBasis, components: comps)
    }
    
    public static func ==(lhs: FreeModuleHom<A, R>, rhs: FreeModuleHom<A, R>) -> Bool {
         // TODO this is incomplete. should not regard order of bases.
        return lhs.domainBasis == rhs.domainBasis && lhs.codomainBasis == rhs.codomainBasis && lhs.matrix == rhs.matrix
    }
    
    public static func +(f: FreeModuleHom<A, R>, g: FreeModuleHom<A, R>) -> FreeModuleHom<A, R> {
        let domain =   (f.domainBasis   + g.domainBasis  ).unique()
        let codomain = (f.codomainBasis + g.codomainBasis).unique()
        
        // TODO very inefficient
        let matrix = DynamicMatrix<R>(rows: codomain.count, cols: domain.count) { (i, j) -> R in
            let (from, to) = (domain[j], codomain[i])
            let x = M(from)
            return (f.appliedTo(x) + g.appliedTo(x))[to]
        }
        return FreeModuleHom(domainBasis: domain, codomainBasis: codomain, matrix: matrix)
    }
    
    public prefix static func -(f: FreeModuleHom<A, R>) -> FreeModuleHom<A, R> {
        return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: -f.matrix)
    }
    
    public static func *(r: R, f: FreeModuleHom<A, R>) -> FreeModuleHom<A, R> {
        return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: r * f.matrix)
    }
    
    public static func *(f: FreeModuleHom<A, R>, r: R) -> FreeModuleHom<A, R> {
        return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: f.matrix * r)
    }
    
    public var hashValue: Int {
        return 0 // TODO
    }
    
    public var description: String {
        return "FreeModuleHom"
    }
    
    public static var symbol: String {
        return "Hom_{\(R.symbol)}"
    }
}
