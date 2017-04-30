import Foundation

public struct FreeModule<_R: Ring>: Module, CustomStringConvertible {
    public typealias R = _R
    
    private let dict: [String : R]
    
    public subscript(a: String) -> R {
        get {
            return dict[a] ?? 0
        }
    }
    
    public init() {
        self.init([:])
    }
    
    public init(_ dict: [String : R]) {
        self.dict = dict
    }
    
    public static var zero: FreeModule<R> {
        return FreeModule<R>.init()
    }
    
    public static func ==<R: Ring>(a: FreeModule<R>, b: FreeModule<R>) -> Bool {
        return a.dict == b.dict
    }
    
    public static func +<R: Ring>(a: FreeModule<R>, b: FreeModule<R>) -> FreeModule<R> {
        let keys = Set(a.dict.keys).union(Set(b.dict.keys))
        let dict = Dictionary.generateBy(keys: keys) {
            a[$0] + b[$0]
        }
        return FreeModule<R>(dict)
    }
    
    public static prefix func -<R: Ring>(a: FreeModule<R>) -> FreeModule<R> {
        let dict = a.dict.mapValues{-$0}
        return FreeModule<R>(dict)
    }
    
    public static func *<R: Ring>(r: R, a: FreeModule<R>) -> FreeModule<R> {
        let dict = a.dict.mapValues{r * $0}
        return FreeModule<R>(dict)
    }
    
    public var description: String {
        return self.dict.map({ "\($1)\($0)"}).joined(separator: " + ")
    }
}

public extension FreeModule {
}
