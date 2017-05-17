import Foundation

public typealias FreeModuleBase = Hashable

public struct FreeModule<A: FreeModuleBase, _R: Ring>: Module, CustomStringConvertible {
    public typealias R = _R
    
    public let basis: [A]
    public let table: [A : R] // FIXME revert!
    
    internal init(basis: [A], table: [A : R]) {
        self.basis = basis
        self.table = table
    }
    
    // generates a basis element
    public init(_ a: A) {
        self.init(basis: [a], table: [a: 1])
    }
    
    public init(basis: [A], values: [R]) {
        guard basis.count == values.count else {
            fatalError("#basis (\(basis.count)) != #values (\(values.count))")
        }
        let pairs = basis.enumerated().map { (i, a) in (a, values[i]) }
        self.init(basis: basis, table: Dictionary(pairs) )
    }

    public static var zero: FreeModule<A, R> {
        return FreeModule<A, R>.init(basis: [], table: [:])
    }
    
    public func coeff(_ a: A) -> R {
        return table[a] ?? 0
    }
    
    public var coeffs: [R] {
        return basis.map{ coeff($0) }
    }
    
    public var description: String {
        let sum =
            basis.map { a in (coeff(a), a) }
                .filter { (r, _) in r != R.zero }
                .map { (r, a) in (r == R.identity) ? "\(a)" : "\(r)\(a)" }
                .joined(separator: " + ")
        
        return sum.isEmpty ? "0" : sum
    }
    
    public static var symbol: String {
        return "FM(\(R.symbol))"
    }
}

// Operations

public func ==<A: FreeModuleBase, R: Ring>(a: FreeModule<A, R>, b: FreeModule<A, R>) -> Bool {
    return a.table == b.table
}

public func +<A: FreeModuleBase, R: Ring>(a: FreeModule<A, R>, b: FreeModule<A, R>) -> FreeModule<A, R> {
    let basis = a.basis + b.basis.filter{!a.basis.contains($0)}
    let table = Dictionary.generateBy(keys: basis) {
        a.coeff($0) + b.coeff($0)
    }
    return FreeModule<A, R>(basis: basis, table: table)
}

public prefix func -<A: FreeModuleBase, R: Ring>(a: FreeModule<A, R>) -> FreeModule<A, R> {
    let table = a.table.mapValues{-$0}
    return FreeModule<A, R>(basis: a.basis, table: table)
}

public func *<A: FreeModuleBase, R: Ring>(r: R, a: FreeModule<A, R>) -> FreeModule<A, R> {
    let table = a.table.mapValues{r * $0}
    return FreeModule<A, R>(basis: a.basis, table: table)
}

public func *<A: FreeModuleBase, R: Ring>(a: FreeModule<A, R>, r: R) -> FreeModule<A, R> {
    let table = a.table.mapValues{$0 * r}
    return FreeModule<A, R>(basis: a.basis, table: table)
}
