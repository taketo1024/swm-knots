import Foundation

public struct Matrix<R: Ring, n: _Int, m: _Int>: AdditiveGroup {
    public var rows: Int { return n.value }
    public var cols: Int { return m.value }
    
    fileprivate var elements: [R]
    
    private func index(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(index: Int) -> R {
        get {
            return elements[index]
        }
        set {
            elements[index] = newValue
        }
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
        let elements = (0 ..< rows * cols).map { (index: Int) -> R in
            let (i, j) = index /% cols
            return gen(i, j)
        }
        self.init(elements: elements)
    }
    
    public static var zero: Matrix<R, n, m> {
        return self.init { _ in 0 }
    }
    
    public static var identity: Matrix<R, n, m> {
        return self.init { $0 == $1 ? 1 : 0 }
    }
}

public typealias ColVector<R: Ring, n: _Int> = Matrix<R, n, _1>
public typealias RowVector<R: Ring, m: _Int> = Matrix<R, _1, m>

public extension Matrix {
    public func rowVector(_ i: Int) -> RowVector<R, m> {
        return RowVector<R, m>{(_, j) -> R in
            return self[i, j]
        }
    }
    
    public func colVector(_ j: Int) -> ColVector<R, n> {
        return ColVector<R, n>{(i, j0) -> R in
            print("\(i), \(j0)")
            return self[i, j0]
        }
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

extension Matrix : Sequence {
    public typealias Iterator = MatrixIterator<R, n, m>
    public func makeIterator() -> Iterator {
        return MatrixIterator(self)
    }
}

public struct MatrixIterator<R: Ring, n: _Int, m: _Int> : IteratorProtocol {
    private let value: Matrix<R, n, m>
    private var current = (0, 0)
    
    public init(_ value: Matrix<R, n, m>) {
        self.value = value
    }
    
    mutating public func next() -> (value: R, row: Int, col: Int)? {
        guard current.0 < n.value && current.1 < m.value else {
            return nil
        }
        
        defer {
            switch current {
            case let c where c.1 + 1 >= m.value:
                current = (c.0 + 1, 0)
            case let c:
                current = (c.0, c.1 + 1)
            }
        }
        
        return (value[current.0, current.1], current.0, current.1)
    }
}

// Elementary Matrix Operations (mutating)

public extension Matrix {
    public mutating func multiplyRow(at i: Int, by r: R) {
        for j in 0 ..< self.cols {
            self[i, j] = r * self[i, j]
        }
    }
    
    public mutating func multiplyCol(at j: Int, by r: R) {
        for i in 0 ..< self.rows {
            self[i, j] = r * self[i, j]
        }
    }
    
    public mutating func addRow(at i0: Int, to i1: Int, multipliedBy r: R = 1) {
        for j in 0 ..< self.cols {
            self[i1, j] = self[i1, j] + (self[i0, j] * r)
        }
    }
    
    public mutating func addCol(at j0: Int, to j1: Int, multipliedBy r: R = 1) {
        for i in 0 ..< self.rows {
            self[i, j1] = self[i, j1] + (self[i, j0] * r)
        }
    }
    
    public mutating func swapRows(_ i0: Int, _ i1: Int) {
        for j in 0 ..< self.cols {
            let a = self[i0, j]
            self[i0, j] = self[i1, j]
            self[i1, j] = a
        }
    }
    
    public mutating func swapCols(_ j0: Int, _ j1: Int) {
        for i in 0 ..< self.rows {
            let a = self[i, j0]
            self[i, j0] = self[i, j1]
            self[i, j1] = a
        }
    }
}

