import Foundation

public struct FreeModule<_R: Ring>: Module, Hashable, CustomStringConvertible {
    public typealias R = _R
    
    internal let dict: [String : R]
    
    public subscript(a: String) -> R {
        get {
            return dict[a] ?? 0
        }
    }
    
    public init(_ name: String) {
        self.init([name: 1])
    }
    
    public init(_ dict: [String : R]) {
        self.dict = dict
    }
    
    public static var zero: FreeModule<R> {
        return FreeModule<R>.init([:])
    }
    
    public var bases: [String] {
        return Array(dict.keys)
    }
    
    public var hashValue: Int {
        return 0 // TODO
    }
    
    public var description: String {
        return dict.isEmpty ? "0" : Array(dict.keys).sorted().map({"\(self[$0])\($0)"}).joined(separator: " + ")
    }
}

// Operations

public func ==<R: Ring>(a: FreeModule<R>, b: FreeModule<R>) -> Bool {
    return a.dict == b.dict
}

public func +<R: Ring>(a: FreeModule<R>, b: FreeModule<R>) -> FreeModule<R> {
    let keys = Set(a.dict.keys).union(Set(b.dict.keys))
    let dict = Dictionary.generateBy(keys: keys) {
        a[$0] + b[$0]
    }
    return FreeModule<R>(dict)
}

public prefix func -<R: Ring>(a: FreeModule<R>) -> FreeModule<R> {
    let dict = a.dict.mapValues{-$0}
    return FreeModule<R>(dict)
}

public func *<R: Ring>(r: R, a: FreeModule<R>) -> FreeModule<R> {
    let dict = a.dict.mapValues{r * $0}
    return FreeModule<R>(dict)
}
