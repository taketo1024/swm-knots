import Foundation

public struct FreeModuleHom<R: Ring>: ModuleHom {
    public typealias M = FreeModule<R>
    public typealias Dom = M
    public typealias Codom = M
    
    private let mapping: [M : M]
    
    public init(_ mapping: [M : M]) {
        self.mapping = mapping
    }
    
    public func appliedTo(_ m: M) -> M {
        return m.bases.reduce(M.zero) { $0 + m[$1] * (mapping[M($1)] ?? M.zero) } // TODO improve
    }
}
