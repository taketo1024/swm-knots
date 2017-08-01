import Foundation

public struct FreeModuleHom<R: Ring, A: FreeModuleBase, B: FreeModuleBase>: ModuleHom {
    public typealias CoeffRing = R
    public typealias Domain   = FreeModule<R, A>
    public typealias Codomain = FreeModule<R, B>
    
    public typealias DomainBasis = [A]
    public typealias CodomainBasis = [B]
    
    public let domainBasis: DomainBasis
    public let codomainBasis: CodomainBasis
    public let matrix: DynamicMatrix<R>
    
    // The root initializer
    public init<n: _Int, m: _Int>(domainBasis: DomainBasis, codomainBasis: CodomainBasis, matrix: Matrix<R, n, m>) {
        self.domainBasis = domainBasis
        self.codomainBasis = codomainBasis
        self.matrix = matrix.asDynamic
    }
    
    public func appliedTo(_ m: Domain) -> Codomain {
        let v: ColVector<R, Dynamic> = ColVector(rows: domainBasis.count) {(i, _) -> R in
            m[domainBasis[i]]
        }
        return Codom(basis: codomainBasis, components: (matrix * v).colArray(0))
    }
    
    public func restrictedTo(domainBasis d: DomainBasis) -> FreeModuleHom<R, A, B> {
        return restrictedTo(domainBasis: d, codomainBasis: codomainBasis)
    }
    
    public func restrictedTo(domainBasis d1: DomainBasis, codomainBasis d2: CodomainBasis) -> FreeModuleHom<R, A, B> {
        let map = FreeModuleHom<R, A, B>.matrixMap(self)
        let matrix = DynamicMatrix<R>(rows: d2.count, cols: d1.count) { (i, j) -> R in
            map(d1[j], d2[i])
        }
        return FreeModuleHom(domainBasis: d1, codomainBasis: d2, matrix: matrix)
    }
    
    public static var zero: FreeModuleHom<R, A, B> {
        return FreeModuleHom(domainBasis: [], codomainBasis: [], matrix: Matrix<R, _0, _0>.zero)
    }
    
    public static func identity(basis: DomainBasis) -> FreeModuleHom<R, A, A> {
        let I = DynamicMatrix<R>(rows: basis.count, cols: basis.count) { (i, j) -> R in (i == j) ? 1 : 0 }
        return FreeModuleHom<R, A, A>(domainBasis: basis, codomainBasis: basis, matrix: I)
    }
    
    public static func ==(lhs: FreeModuleHom<R, A, B>, rhs: FreeModuleHom<R, A, B>) -> Bool {
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
    
    public static func +(f: FreeModuleHom<R, A, B>, g: FreeModuleHom<R, A, B>) -> FreeModuleHom<R, A, B> {
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
    
    public prefix static func -(f: FreeModuleHom<R, A, B>) -> FreeModuleHom<R, A, B> {
        return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: -f.matrix)
    }
    
    public static func *(r: R, f: FreeModuleHom<R, A, B>) -> FreeModuleHom<R, A, B> {
        return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: r * f.matrix)
    }
    
    public static func *(f: FreeModuleHom<R, A, B>, r: R) -> FreeModuleHom<R, A, B> {
        return FreeModuleHom(domainBasis: f.domainBasis, codomainBasis: f.codomainBasis, matrix: f.matrix * r)
    }
    
    public static func ⊗<C: FreeModuleBase, D: FreeModuleBase>(f: FreeModuleHom<R, A, B>, g: FreeModuleHom<R, C, D>) -> FreeModuleHom<R, Tensor<A, C>, Tensor<B, D>> {
        let (k, l) = (g.codomainBasis.count, g.domainBasis.count)
        
        let domain = f.domainBasis.pairs(with: g.domainBasis).map{ (a, b) in a⊗b }
        let codomain = f.codomainBasis.pairs(with: g.codomainBasis).map{ (a, b) in a⊗b }
        let matrix = DynamicMatrix<R>(rows: codomain.count, cols: domain.count) { (i, j) -> R in
            f.matrix[i / k, j / l] * g.matrix[i % k, j % l]
        }
        return FreeModuleHom<R, Tensor<A, C>, Tensor<B, D>>(domainBasis: domain, codomainBasis: codomain, matrix: matrix)
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
