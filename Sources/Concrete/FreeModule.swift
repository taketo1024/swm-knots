import Foundation

public typealias FreeModuleBase = Hashable

public struct FreeModule<A: FreeModuleBase, _R: Ring>: Module, CustomStringConvertible {
    public typealias R = _R
    
    public let basis: [A]
    internal let values: [R]
    internal let table: [A: R]
    
    // root initializer
    public init(basis: [A], values: [R]) {
        guard basis.count == values.count else {
            fatalError("#basis (\(basis.count)) != #values (\(values.count))")
        }
        self.basis = basis
        self.values = values
        self.table = Dictionary(Array(zip(basis, values)))
    }
    
    public init(_ table: [A : R]) {
        let basis = Array(table.keys)
        let values = basis.map{ table[$0] ?? R.zero }
        self.init(basis: basis, values: values)
    }
    
    // generates a basis element
    public init(_ a: A) {
        self.init(basis: [a], values: [1])
    }
    
    public static var zero: FreeModule<A, R> {
        return FreeModule<A, R>.init(basis: [], values: [])
    }
    
    public func value(forBasisElement a: A) -> R {
        return table[a] ?? R.zero
    }
    
    public var description: String {
        let sum = basis.enumerated()
            .map {($1, values[$0])}
            .filter{ (_, r) in r != R.zero }
            .map { (a, r) in (r == R.identity) ? "\(a)" : "\(r)\(a)" }
            .joined(separator: " + ")
        
        return sum.isEmpty ? "0" : sum
    }
    
    public static var symbol: String {
        return "FM(\(R.symbol))"
    }
}

// Operations

public func ==<A: FreeModuleBase, R: Ring>(a: FreeModule<A, R>, b: FreeModule<A, R>) -> Bool {
    return a.table == b.table // bases need not be in same order.
}

public func +<A: FreeModuleBase, R: Ring>(a: FreeModule<A, R>, b: FreeModule<A, R>) -> FreeModule<A, R> {
    let basis = (a.basis + b.basis).unique()
    let values = basis.map { x in a.value(forBasisElement: x) + b.value(forBasisElement: x) }
    return FreeModule<A, R>(basis: basis, values: values)
}

public prefix func -<A: FreeModuleBase, R: Ring>(a: FreeModule<A, R>) -> FreeModule<A, R> {
    let values = a.values.map{-$0}
    return FreeModule<A, R>(basis: a.basis, values: values)
}

public func *<A: FreeModuleBase, R: Ring>(r: R, a: FreeModule<A, R>) -> FreeModule<A, R> {
    let values = a.values.map{r * $0}
    return FreeModule<A, R>(basis: a.basis, values: values)
}

public func *<A: FreeModuleBase, R: Ring>(a: FreeModule<A, R>, r: R) -> FreeModule<A, R> {
    let values = a.values.map{$0 * r}
    return FreeModule<A, R>(basis: a.basis, values: values)
}

public extension FreeModule {
    public static func transform<n:_Int, m:_Int>(elements: [FreeModule<A, R>], matrix Q: Matrix<R, n, m>) -> [FreeModule<A, R>] {
        if elements.isEmpty {
            return []
        }
        
        let basis = elements.first!.basis
        let P = Matrix<R, _TypeLooseSize, n>(rows: basis.count, cols: elements.count) { (i, j) in
            elements[j].values[i]
        }
        let PQ = P * Q
        
        return (0 ..< Q.cols).map{ j in FreeModule<A, R>(basis: basis, values: PQ.colArray(j)) }
    }
}
