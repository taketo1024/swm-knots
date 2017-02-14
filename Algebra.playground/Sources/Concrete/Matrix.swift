import Foundation

public struct Matrix<R: Ring, n: _Int, m: _Int>: AdditiveGroup {
    public var rows: Int { return n.value }
    public var cols: Int { return m.value }
    
    fileprivate var elements: [R]
    
    private func index(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(i: Int, j: Int) -> R {
        get {
            return elements[index(i, j)]
        }
        set {
            elements[index(i, j)] = newValue
        }
    }
    
    public init(_ value: Int) {
        self.init({
            ($0 == $1) ? R(value) : 0
        })
    }
    
    private init(elements: [R]) {
        self.elements = elements
    }
    
    public init(_ elements: R...) {
        self.init(elements: elements)
    }
    
    public init(_ gen: (Int, Int) -> R) {
        let rows = n.value
        let cols = m.value
        let elements = (0 ..< rows * cols).map { gen($0 / rows, $0 % cols) }
        self.init(elements: elements)
    }
    
    public static var zero: Matrix<R, n, m> {
        return self.init { _ in 0 }
    }
    
    public static var identity: Matrix<R, n, m> {
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

public func == <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Bool {
    for i in 0 ..< n.value {
        for j in 0 ..< m.value {
            if a[i, j] != b[i, j] {
                return false
            }
        }
    }
    return true
}

public func + <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return Matrix<R, n, m>{ (i, j) -> R in
        return a[i, j] + b[i, j]
    }
}

public prefix func - <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return Matrix<R, n, m>{ (i, j) -> R in
        return -a[i, j]
    }
}

public func - <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return Matrix<R, n, m>{ (i, j) -> R in
        return a[i, j] + b[i, j]
    }
}

public func * <R: Ring, n: _Int, m: _Int>(r: R, b: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return Matrix<R, n, m> { (i, j) -> R in
        return r * b[i, j]
    }
}

public func * <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, r: R) -> Matrix<R, n, m> {
    return Matrix<R, n, m> { (i, j) -> R in
        return a[i, j] * r
    }
}

public func * <R: Ring, n: _Int, m: _Int, p: _Int>(a: Matrix<R, n, m>, b: Matrix<R, m, p>) -> Matrix<R, n, p> {
    return Matrix<R, n, p> { (i, k) -> R in
        return (0 ..< m.value)
                .map({j in a[i, j] * b[j, k]})
                .reduce(0) {$0 + $1}
    }
}

public func ** <R: Ring, n: _Int>(a: Matrix<R, n, n>, b: Int) -> Matrix<R, n, n> {
    return b == 0 ? Matrix<R, n, n>.identity : a * (a ** (b - 1))
}

public func det<R: Ring, n: _Int>(a: Matrix<R, n, n>) -> R {
    return Permutation<n>.all.reduce(0) {
        (res: R, s: Permutation<n>) -> R in
        res + R(sgn(s)) * (0 ..< n.value).reduce(1) {
            (p: R, i: Int) -> R in
            p * a[i, s[i]]
        }
    }
}
