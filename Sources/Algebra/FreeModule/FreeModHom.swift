import Foundation

public struct FreeModuleHom<A: FreeModuleBase, B: FreeModuleBase, R: Ring>: ModuleHom {
    public typealias CoeffRing = R
    public typealias Domain    = FreeModule<A, R>
    public typealias Codomain  = FreeModule<B, R>
    
    private let f: (A) -> Codomain
    
    public init(_ f: @escaping (A) -> Codomain) {
        self.f = f
    }
    
    public init<n, m>(from: [A], to: [B], matrix: Matrix<n, m, R>) {
        self.f = { a in
            if let j = from.index(of: a) {
                return Codomain(zip(to, matrix.colVector(j).grid))
            } else {
                return Codomain.zero
            }
        }
    }
    
    public func applied(to a: A) -> Codomain {
        return f(a)
    }
    
    public func applied(to m: Domain) -> Codomain {
        var d: [B : R] = [:]
        for (a, r) in m {
            for (b, s) in self.applied(to: a) {
                d[b] = d[b, default: .zero] + r * s
            }
        }
        return Codomain(d)
    }
    
    public static var zero: FreeModuleHom<A, B, R> {
        return FreeModuleHom { _ in Codomain.zero }
    }
    
    public static var identity: FreeModuleHom<A, A, R> {
        return FreeModuleHom<A, A, R> { a in FreeModule(a) }
    }
    
    public static func ==(lhs: FreeModuleHom<A, B, R>, rhs: FreeModuleHom<A, B, R>) -> Bool {
        fatalError("FreeModuleHom.== is unavailable.")
    }
    
    public static func +(f: FreeModuleHom<A, B, R>, g: FreeModuleHom<A, B, R>) -> FreeModuleHom<A, B, R> {
        return FreeModuleHom { a in f.applied(to: a) + g.applied(to: a) }
    }
    
    public prefix static func -(f: FreeModuleHom<A, B, R>) -> FreeModuleHom<A, B, R> {
        return FreeModuleHom { a in -f.applied(to: a) }
    }
    
    public static func *(r: R, f: FreeModuleHom<A, B, R>) -> FreeModuleHom<A, B, R> {
        return FreeModuleHom { a in r * f.applied(to: a) }
    }
    
    public static func *(f: FreeModuleHom<A, B, R>, r: R) -> FreeModuleHom<A, B, R> {
        return FreeModuleHom { a in f.applied(to: a) * r }
    }
    
    public static func ∘<C>(g: FreeModuleHom<B, C, R>, f: FreeModuleHom<A, B, R>) -> FreeModuleHom<A, C, R> {
        return FreeModuleHom<A, C, R> { a in g.applied(to: f.applied(to: a)) }
    }
    
    public static func ⊗<C, D>(f: FreeModuleHom<A, B, R>, g: FreeModuleHom<C, D, R>) -> FreeModuleHom<Tensor<A, C>, Tensor<B, D>, R> {
        return FreeModuleHom<Tensor<A, C>, Tensor<B, D>, R> { t in
            let (a, b) = (t._1, t._2)
            return f.applied(to: a) ⊗ g.applied(to: b)
        }
    }
    
    public var hashValue: Int {
        return 0 // TODO
    }
}
