import Foundation

public struct FreeModule<Key: Hashable, _R: Ring>: Module, Hashable, CustomStringConvertible {
    public typealias R = _R
    internal let dict: [Key : R]
    
    public subscript(a: Key) -> R {
        get {
            return dict[a] ?? 0
        }
    }
    
    public init(_ key: Key) {
        self.dict = [key: 1]
    }
    
    public init(_ dict: [Key : R]) {
        self.dict = dict
    }
    
    public static var zero: FreeModule<Key, R> {
        return FreeModule<Key, R>.init([:])
    }
    
    public var bases: [Key] {
        return Array(dict.keys)
    }
    
    public func coeff(_ key: Key) -> R {
        return dict[key] ?? 0
    }
    
    public var hashValue: Int {
        return 0 // TODO
    }
    
    public var description: String {
        let sum = Array(dict.keys)
            .map({(m) in
                switch coeff(m) {
                case R.zero:     return ""
                case R.identity: return "\(m)"
                case let r:      return "\(r)\(m)"
                }
            })
            .filter({$0 != ""})
            .joined(separator: " + ")
        return sum.isEmpty ? "0" : sum
    }
}

// Operations

public func ==<Key: Hashable, R: Ring>(a: FreeModule<Key, R>, b: FreeModule<Key, R>) -> Bool {
    return a.dict == b.dict
}

public func +<Key: Hashable, R: Ring>(a: FreeModule<Key, R>, b: FreeModule<Key, R>) -> FreeModule<Key, R> {
    let keys = Set(a.dict.keys).union(Set(b.dict.keys))
    let dict = Dictionary.generateBy(keys: keys) {
        a[$0] + b[$0]
    }
    return FreeModule<Key, R>(dict)
}

public prefix func -<Key: Hashable, R: Ring>(a: FreeModule<Key, R>) -> FreeModule<Key, R> {
    let dict = a.dict.mapValues{-$0}
    return FreeModule<Key, R>(dict)
}

public func *<Key: Hashable, R: Ring>(r: R, a: FreeModule<Key, R>) -> FreeModule<Key, R> {
    let dict = a.dict.mapValues{r * $0}
    return FreeModule<Key, R>(dict)
}

public func *<Key: Hashable, R: Ring>(a: FreeModule<Key, R>, r: R) -> FreeModule<Key, R> {
    let dict = a.dict.mapValues{$0 * r}
    return FreeModule<Key, R>(dict)
}
