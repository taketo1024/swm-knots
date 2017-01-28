 import Foundation

public struct Matrix<K: Ring, n: TPInt, m: TPInt>: Equatable {
    public var rows: Int { return n.value }
    public var cols: Int { return m.value }
    
    fileprivate var elements: [K]
    
    private func index(_ i: Int, _ j: Int) -> Int {
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
        let rows = n.value
        let cols = m.value
        let elements = (0 ..< rows * cols).map { gen($0 / rows, $0 % cols) }
        self.init(elements: elements)
    }
    
    public static var zero: Matrix<K, n, m> {
        return self.init { _ in 0 }
    }
    
    public static var identity: Matrix<K, n, m> {
        return self.init { $0 == $1 ? 1 : 0 }
    }
}

extension Matrix: CustomStringConvertible {
    public var description: String {
        return "[" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joined(separator: ", ")
        }).joined(separator: "; ") + "]"
    }
}

public func == <K: Ring, n: TPInt, m: TPInt>(a: Matrix<K, n, m>, b: Matrix<K, n, m>) -> Bool {
    for i in 0 ..< n.value {
        for j in 0 ..< m.value {
            if a[i, j] != b[i, j] {
                return false
            }
        }
    }
    return true
}

public func + <K: Ring, n: TPInt, m: TPInt>(a: Matrix<K, n, m>, b: Matrix<K, n, m>) -> Matrix<K, n, m> {
    return Matrix<K, n, m>{ (i, j) -> K in
        return a[i, j] + b[i, j]
    }
}

public prefix func - <K: Ring, n: TPInt, m: TPInt>(a: Matrix<K, n, m>) -> Matrix<K, n, m> {
    return Matrix<K, n, m>{ (i, j) -> K in
        return -a[i, j]
    }
}

public func - <K: Ring, n: TPInt, m: TPInt>(a: Matrix<K, n, m>, b: Matrix<K, n, m>) -> Matrix<K, n, m> {
    return Matrix<K, n, m>{ (i, j) -> K in
        return a[i, j] + b[i, j]
    }
}

public func * <K: Ring, n: TPInt, m: TPInt>(k: K, b: Matrix<K, n, m>) -> Matrix<K, n, m> {
    return Matrix<K, n, m> { (i, j) -> K in
        return k * b[i, j]
    }
}

public func * <K: Ring, n: TPInt, m: TPInt>(a: Matrix<K, n, m>, k: K) -> Matrix<K, n, m> {
    return Matrix<K, n, m> { (i, j) -> K in
        return a[i, j] * k
    }
}

public func * <K: Ring, n: TPInt, m: TPInt, p: TPInt>(a: Matrix<K, n, m>, b: Matrix<K, m, p>) -> Matrix<K, n, p> {
    return Matrix<K, n, p> { (i, k) -> K in
        return (0 ..< m.value)
                .map({j in a[i, j] * b[j, k]})
                .reduce(0) {$0 + $1}
    }
}

public func ** <K: Ring, n: TPInt>(a: Matrix<K, n, n>, b: Int) -> Matrix<K, n, n> {
    return b == 0 ? Matrix<K, n, n>.identity : a * (a ** (b - 1))
}

public func det<K: Ring, n: TPInt>(A: Matrix<K, n, n>) -> K {
    return Permutation<n>.all.reduce(0) {
        (res: K, s: Permutation<n>) -> K in
        res + K(sgn(s)) * (0 ..< n.value).reduce(1) {
            (p: K, i: Int) -> K in
            p * A[i, s[i]]
        }
    }
}
