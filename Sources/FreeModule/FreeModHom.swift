import Foundation

public struct FreeModuleHom<A: FreeModuleBase, B: FreeModuleBase, R: Ring>: ModuleHom {
    public typealias CoeffRing = R
    
    public typealias Domain = FreeModule<A, R>
    public typealias DomainBasis = [A]
    public typealias Codomain = FreeModule<B, R>
    public typealias CodomainBasis = [B]
    
    public let domainBasis: DomainBasis
    public let codomainBasis: CodomainBasis
    public let matrix: DynamicMatrix<R>
    
    // The root initializer
    public init<n, m>(domainBasis: DomainBasis, codomainBasis: CodomainBasis, matrix: Matrix<n, m, R>) {
        self.domainBasis = domainBasis
        self.codomainBasis = codomainBasis
        self.matrix = matrix.asDynamic
    }
    
    public init(domainBasis: DomainBasis, codomainBasis: CodomainBasis, mapping: (A) -> [(B, R)]) {
        let components = domainBasis.enumerated().flatMap{ (j, a) -> [MatrixComponent<R>] in
            mapping(a).map { (b, r) -> MatrixComponent<R> in
                let i = codomainBasis.index(of: b)!
                return (i, j, r)
            }
        }
        let matrix = DynamicMatrix<R>(rows: codomainBasis.count, cols: domainBasis.count, components: components)
        self.init(domainBasis: domainBasis, codomainBasis: codomainBasis, matrix: matrix)
    }
    
    public func appliedTo(_ m: Domain) -> Codomain {
        let v: ColVector<Dynamic, R> = ColVector(rows: domainBasis.count) {(i, _) -> R in
            m[domainBasis[i]]
        }
        return FreeModule<B, R>(basis: codomainBasis, components: (matrix * v).colArray(0))
    }
    
    public func restrictedTo(domainBasis d: DomainBasis) -> FreeModuleHom<A, B, R> {
        return restrictedTo(domainBasis: d, codomainBasis: codomainBasis)
    }
    
    public func restrictedTo(domainBasis d1: DomainBasis, codomainBasis d2: CodomainBasis) -> FreeModuleHom<A, B, R> {
        let map = FreeModuleHom<A, B, R>.matrixMap(self)
        let matrix = DynamicMatrix<R>(rows: d2.count, cols: d1.count) { (i, j) -> R in
            map(d1[j], d2[i])
        }
        return FreeModuleHom(domainBasis: d1, codomainBasis: d2, matrix: matrix)
    }
    
    public static var zero: FreeModuleHom<A, B, R> {
        return FreeModuleHom(domainBasis: [], codomainBasis: [], matrix: Matrix<_0, _0, R>.zero)
    }
    
    public static func identity(basis: DomainBasis) -> FreeModuleHom<A, A, R> {
        let I = DynamicMatrix<R>(rows: basis.count, cols: basis.count) { (i, j) -> R in (i == j) ? 1 : 0 }
        return FreeModuleHom<A, A, R>(domainBasis: basis, codomainBasis: basis, matrix: I)
    }
    
    public static func ==(lhs: FreeModuleHom<A, B, R>, rhs: FreeModuleHom<A, B, R>) -> Bool {
        if (lhs.domainBasis == rhs.domainBasis) && (lhs.codomainBasis == rhs.codomainBasis) && (lhs.matrix == rhs.matrix) {
            return true
            
        }
        
        if (Set(lhs.domainBasis) == Set(rhs.domainBasis)) && (Set(lhs.codomainBasis) == Set(rhs.codomainBasis)) {
            let p1 = Permutation<Dynamic>(from: rhs.domainBasis, to: lhs.domainBasis).asMatrix(type: R.self)
            let p2 = Permutation<Dynamic>(from: lhs.codomainBasis, to: rhs.codomainBasis).asMatrix(type: R.self)
            return rhs.matrix == p2 * lhs.matrix * p1
        }
        
        return false
    }
    
    public static func +(f: FreeModuleHom<A, B, R>, g: FreeModuleHom<A, B, R>) -> FreeModuleHom<A, B, R> {
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
    
    public prefix static func -(f: FreeModuleHom<A, B, R>) -> FreeModuleHom<A, B, R> {
        return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: -f.matrix)
    }
    
    public static func *(r: R, f: FreeModuleHom<A, B, R>) -> FreeModuleHom<A, B, R> {
        return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: r * f.matrix)
    }
    
    public static func *(f: FreeModuleHom<A, B, R>, r: R) -> FreeModuleHom<A, B, R> {
        return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: f.matrix * r)
    }
    
    public static func ∘<C>(g: FreeModuleHom<B, C, R>, f: FreeModuleHom<A, B, R>) -> FreeModuleHom<A, C, R> {
        let p = DynamicMatrix<R>(rows: g.matrix.cols, cols: f.matrix.rows, components: f.codomainBasis.flatMap { (b: B) -> MatrixComponent<R>? in
            
            let j = f.codomainBasis.index(of: b)!
            if let i = g.domainBasis.index(of: b) {
                return (i, j, R.identity)
            } else {
                return nil
            }
        })
        return FreeModuleHom<A, C, R>(domainBasis: f.domainBasis, codomainBasis: g.codomainBasis, matrix: g.matrix * p * f.matrix)
    }
    
    public static func ⊗<C, D>(f: FreeModuleHom<A, B, R>, g: FreeModuleHom<C, D, R>) -> FreeModuleHom<Tensor<A, C>, Tensor<B, D>, R> {
        let (k, l) = (g.codomainBasis.count, g.domainBasis.count)
        
        let domain = f.domainBasis.allCombinations(with: g.domainBasis).map{ (a, b) in a⊗b }
        let codomain = f.codomainBasis.allCombinations(with: g.codomainBasis).map{ (a, b) in a⊗b }
        let matrix = DynamicMatrix<R>(rows: codomain.count, cols: domain.count) { (i, j) -> R in
            f.matrix[i / k, j / l] * g.matrix[i % k, j % l]
        }
        return FreeModuleHom<Tensor<A, C>, Tensor<B, D>, R>(domainBasis: domain, codomainBasis: codomain, matrix: matrix)
    }
    
    public var hashValue: Int {
        return 0 // TODO
    }
    
    public var description: String {
        return "(\(domainBasis) -> \(codomainBasis))"
    }
    
    public var detailDescription: String {
        return description + "\n" + matrix.detailDescription + "\n"
    }
    
    public static var symbol: String {
        return "Hom_{\(R.symbol)}"
    }
    
    private static func matrixMap(_ f: FreeModuleHom) -> ((A, B) -> R) {
        let domainIndex:   [A: Int] = Dictionary(pairs: f.domainBasis  .enumerated().map{ ($1, $0) })
        let codomainIndex: [B: Int] = Dictionary(pairs: f.codomainBasis.enumerated().map{ ($1, $0) })
        return {(from: A, to: B) -> R in
            if let i = codomainIndex[to], let j = domainIndex[from] {
                return f.matrix[i, j]
            } else {
                return R.zero
            }
        }
    }
}
