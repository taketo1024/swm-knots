import Foundation

public struct FreeModule<A: Hashable, _R: Ring>: Module, CustomStringConvertible {
    public typealias R = _R
    internal let dict: [A : R]
    
    internal init(_ dict: [A : R]) {
        self.dict = dict
    }
    
    // generates a basis element
    public init(_ a: A) {
        self.init([a: 1])
    }
    
    public init(_ pairs: (R, A)...) {
        let dict = Dictionary(pairs.map{($1, $0)})
        self.init(dict)
    }
    
    public static var zero: FreeModule<A, R> {
        return FreeModule<A, R>.init([:])
    }
    
    public var isBasis: Bool {
        return dict.count == 1 && dict.values.first! == R.identity
    }
    
    public var basisElement: A {
        return dict.keys.first!
    }
    
    public var basisElements: [A] {
        return Array(dict.keys)
    }
    
    public func coeff(_ basisElement: A) -> R {
        return dict[basisElement] ?? 0
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

public func ==<A: Hashable, R: Ring>(a: FreeModule<A, R>, b: FreeModule<A, R>) -> Bool {
    return a.dict == b.dict
}

public func +<A: Hashable, R: Ring>(a: FreeModule<A, R>, b: FreeModule<A, R>) -> FreeModule<A, R> {
    let basisElements = Set(a.dict.keys).union(Set(b.dict.keys))
    let dict = Dictionary.generateBy(keys: basisElements) {
        a.coeff($0) + b.coeff($0)
    }
    return FreeModule<A, R>(dict)
}

public prefix func -<A: Hashable, R: Ring>(a: FreeModule<A, R>) -> FreeModule<A, R> {
    let dict = a.dict.mapValues{-$0}
    return FreeModule<A, R>(dict)
}

public func *<A: Hashable, R: Ring>(r: R, a: FreeModule<A, R>) -> FreeModule<A, R> {
    let dict = a.dict.mapValues{r * $0}
    return FreeModule<A, R>(dict)
}

public func *<A: Hashable, R: Ring>(a: FreeModule<A, R>, r: R) -> FreeModule<A, R> {
    let dict = a.dict.mapValues{$0 * r}
    return FreeModule<A, R>(dict)
}
