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
