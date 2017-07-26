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
    
    public func appliedTo(_ m: M) -> M {
        let v: ColVector<R, Dynamic> = ColVector(rows: domainBasis.count) {(i, _) -> R in
            m[domainBasis[i]]
        }
        return M(basis: codomainBasis, components: (matrix * v).colArray(0))
    }
    
    public func restrictedTo(domainBasis d: Basis) -> FreeModuleHom<A, R> {
        return restrictedTo(domainBasis: d, codomainBasis: codomainBasis)
    }
    
    public func restrictedTo(domainBasis d1: Basis, codomainBasis d2: Basis) -> FreeModuleHom<A, R> {
        let map = FreeModuleHom<A, R>.matrixMap(self)
        let matrix = DynamicMatrix<R>(rows: d2.count, cols: d1.count) { (i, j) -> R in
            map(d1[j], d2[i])
        }
        return FreeModuleHom(domainBasis: d1, codomainBasis: d2, matrix: matrix)
    }
    
    public static var zero: FreeModuleHom<A, R> {
        return FreeModuleHom(domainBasis: [], codomainBasis: [], matrix: Matrix<R, _0, _0>.zero)
    }
    
    public static func identity(basis: Basis) -> FreeModuleHom<A, R> {
        let I = DynamicMatrix<R>(rows: basis.count, cols: basis.count) { (i, j) -> R in (i == j) ? 1 : 0 }
        return FreeModuleHom(domainBasis: basis, codomainBasis: basis, matrix: I)
    }
    
    public static func ==(lhs: FreeModuleHom<A, R>, rhs: FreeModuleHom<A, R>) -> Bool {
         // TODO this is incomplete. should not regard order of bases.
        return lhs.domainBasis == rhs.domainBasis && lhs.codomainBasis == rhs.codomainBasis && lhs.matrix == rhs.matrix
    }
    
    public static func +(f: FreeModuleHom<A, R>, g: FreeModuleHom<A, R>) -> FreeModuleHom<A, R> {
        // case: the dom/codom of f and g are same.
        if f.domainBasis == g.domainBasis && f.codomainBasis == g.codomainBasis {
            return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: f.matrix + g.matrix)
        }
        
        // case: the dom/codom of f and g are disjoint (direct sum)
        if Set(f.domainBasis).isDisjoint(with: g.domainBasis) && Set(f.codomainBasis).isDisjoint(with: g.codomainBasis) {
            let (n1, m1) = (f.codomainBasis.count, f.domainBasis.count)
            let (n2, m2) = (g.codomainBasis.count, g.domainBasis.count)
            let matrix = DynamicMatrix<R>(rows: n1 + n2, cols: m1 + m2) { (i, j) -> R in
                if i < n1 && j < m1 {
                    return f.matrix[i, j]
                } else if i >= n1 && j >= m1 {
                    return g.matrix[i - n1, j - m1]
                } else {
                    return R.zero
                }
            }
            
            return FreeModuleHom(domainBasis: f.domainBasis + g.domainBasis,
                                 codomainBasis: f.codomainBasis + g.codomainBasis,
                                 matrix: matrix)
        }
        
        // general case.
        let domain =   (f.domainBasis   + g.domainBasis  ).unique()
        let codomain = (f.codomainBasis + g.codomainBasis).unique()
        
        let fMap = matrixMap(f)
        let gMap = matrixMap(g)
        
        let matrix = DynamicMatrix<R>(rows: codomain.count, cols: domain.count) { (i, j) -> R in
            let (from, to) = (domain[j], codomain[i])
            return fMap(from, to) + gMap(from, to)
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
    
    public static func ⊗<B: FreeModuleBase>(f: FreeModuleHom<A, R>, g: FreeModuleHom<B, R>) -> FreeModuleHom<Tensor<A, B>, R> {
        let (k, l) = (g.codomainBasis.count, g.domainBasis.count)
        
        let domain = f.domainBasis.pairs(with: g.domainBasis).map{ (a, b) in a⊗b }
        let codomain = f.codomainBasis.pairs(with: g.codomainBasis).map{ (a, b) in a⊗b }
        let matrix = DynamicMatrix<R>(rows: codomain.count, cols: domain.count) { (i, j) -> R in
            f.matrix[i / k, j / l] * g.matrix[i % k, j % l]
        }
        return FreeModuleHom<Tensor<A, B>, R>(domainBasis: domain, codomainBasis: codomain, matrix: matrix)
    }
    
    public var hashValue: Int {
        return 0 // TODO
    }
    
    public var description: String {
        return "(\(domainBasis) -> \(codomainBasis))"
    }
    
    public var debugDescription: String {
        return description + "\n" + matrix.debugDescription + "\n"
    }
    
    public static var symbol: String {
        return "Hom_{\(R.symbol)}"
    }
    
    private static func matrixMap(_ f: FreeModuleHom) -> ((A, A) -> R) {
        let domainIndex:   [A: Int] = Dictionary(pairs: f.domainBasis  .enumerated().map{ ($1, $0) })
        let codomainIndex: [A: Int] = Dictionary(pairs: f.codomainBasis.enumerated().map{ ($1, $0) })
        return {(from: A, to: A) -> R in
            if let i = codomainIndex[to], let j = domainIndex[from] {
                return f.matrix[i, j]
            } else {
                return R.zero
            }
        }
    }
}
