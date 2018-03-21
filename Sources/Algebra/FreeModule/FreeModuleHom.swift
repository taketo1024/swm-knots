import Foundation

public struct FreeModuleHom<A: FreeModuleBase, B: FreeModuleBase, R: Ring>: _ModuleHom {
    public typealias CoeffRing = R
    public typealias Domain    = FreeModule<A, R>
    public typealias Codomain  = FreeModule<B, R>
    
    private let f: (Domain) -> Codomain
    
    // MEMO: determined by the image of the basis.
    public init(_ f: @escaping (A) -> Codomain) {
        self.init { (m: Domain) in
            var d: [B : R] = [:]
            for (a, r) in m {
                for (b, s) in f(a) {
                    d[b] = d[b, default: .zero] + r * s
                }
            }
            return Codomain(d)
        }
    }
    
    public init(_ f: @escaping (Domain) -> Codomain) {
        self.f = f
    }
    
    public func applied(to a: A) -> Codomain {
        return f(FreeModule(a))
    }
    
    public func applied(to m: Domain) -> Codomain {
        return f(m)
    }
    
    public static func ∘<C>(g: FreeModuleHom<B, C, R>, f: FreeModuleHom<A, B, R>) -> FreeModuleHom<A, C, R> {
        return FreeModuleHom<A, C, R> { (a: A) in g.applied(to: f.applied(to: a)) }
    }
    
    public static func ⊕<A2, B2>(f1: FreeModuleHom<A, B, R>, f2: FreeModuleHom<A2, B2, R>) -> FreeModuleHom<Sum<A, A2>, Sum<B, B2>, R> {
        return FreeModuleHom<Sum<A, A2>, Sum<B, B2>, R> { (c: Sum<A, A2>) in
            switch c {
            case let ._1(a1): return FreeModule(f1.applied(to: a1)) ⊕ .zero
            case let ._2(a2): return .zero ⊕ FreeModule(f2.applied(to: a2))
            }
        }
    }

    public static func ⊗<C, D>(f: FreeModuleHom<A, B, R>, g: FreeModuleHom<C, D, R>) -> FreeModuleHom<Tensor<A, C>, Tensor<B, D>, R> {
        return FreeModuleHom<Tensor<A, C>, Tensor<B, D>, R> { (t: Tensor<A, C>) in
            let (a, b) = (t._1, t._2)
            return f.applied(to: a) ⊗ g.applied(to: b)
        }
    }
}

public extension FreeModuleHom where B == Sum<A, A> {
    public static var diagonal: FreeModuleHom<A, Sum<A, A>, R> {
        return FreeModuleHom { (a: A) in
            FreeModule([(._1(a), .identity), (._2(a), .identity)])
        }
    }
}
