import Foundation

public struct Matrix<K: Ring, Rows: TPInt, Cols: TPInt> {
    public var rows: Int { return Rows.value }
    public var cols: Int { return Cols.value }
    
    private var elements: [K]
    
    private func index(i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(i: Int, j: Int) -> K {
        get {
            return elements[index(i, j)]
        }
        set {
            elements[index(i, j)] = newValue
        }
    }
    
    private init(elements: [K]) {
        self.elements = elements
    }
    
    public init(_ elements: K...) {
        self.init(elements: elements)
    }
    
    public init(_ gen: (Int, Int) -> K) {
        let rows = Rows.value
        let cols = Cols.value
        let elements = (0 ..< rows * cols).map { gen($0 / rows, $0 % cols) }
        self.init(elements: elements)
    }
    
    public static var zero: Matrix<K, Rows, Cols> {
        return self.init { _ in K(0) }
    }
    
    public static var identity: Matrix<K, Rows, Cols> {
        return self.init { $0 == $1 ? K(1) : K(0) }
    }
}

extension Matrix: CustomStringConvertible {
    public var description: String {
        return "[" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joinWithSeparator(", ")
        }).joinWithSeparator("; ") + "]"
    }
}

public func +<K: Ring, n: TPInt, m: TPInt>(lhs: Matrix<K, n, m>, rhs: Matrix<K, n, m>) -> Matrix<K, n, m> {
    return Matrix<K, n, m>{ (i, j) -> K in
        return lhs[i, j] + rhs[i, j]
    }
}

public prefix func -<K: Ring, n: TPInt, m: TPInt>(lhs: Matrix<K, n, m>) -> Matrix<K, n, m> {
    return Matrix<K, n, m>{ (i, j) -> K in
        return -lhs[i, j]
    }
}

public func -<K: Ring, n: TPInt, m: TPInt>(lhs: Matrix<K, n, m>, rhs: Matrix<K, n, m>) -> Matrix<K, n, m> {
    return Matrix<K, n, m>{ (i, j) -> K in
        return lhs[i, j] + rhs[i, j]
    }
}

public func *<K: Ring, n: TPInt, m: TPInt>(k: K, rhs: Matrix<K, n, m>) -> Matrix<K, n, m> {
    return Matrix<K, n, m> { (i, j) -> K in
        return k * rhs[i, j]
    }
}

public func *<K: Ring, n: TPInt, m: TPInt>(lhs: Matrix<K, n, m>, k: K) -> Matrix<K, n, m> {
    return Matrix<K, n, m> { (i, j) -> K in
        return lhs[i, j] * k
    }
}

public func *<K: Ring, n: TPInt, m: TPInt, p: TPInt>(lhs: Matrix<K, n, m>, rhs: Matrix<K, m, p>) -> Matrix<K, n, p> {
    return Matrix<K, n, p> { (i, k) -> K in
        return (0 ..< m.value)
                .map({j in lhs[i, j] * rhs[j, k]})
                .reduce(K(0), combine: {$0 + $1})
    }
}

public func ^<K: Ring, n: TPInt>(lhs: Matrix<K, n, n>, rhs: Int) -> Matrix<K, n, n> {
    return (rhs == 0) ? Matrix<K, n, n>.identity : lhs * (lhs ^ (rhs - 1))
}

public func det<K: Ring, n: TPInt>(A: Matrix<K, n, n>) -> K {
    return Permutation<n>.all.reduce(K(0), combine: {
        (res: K, s: Permutation<n>) -> K in
        res + K(sgn(s)) * (0 ..< n.value).reduce(K(1), combine: {
            (p: K, i: Int) -> K in
            p * A[i, s[i]]
        })
    })
}
