import Foundation

public struct Matrix<_R: Ring, n: _Int, m: _Int>: Module, Sequence, CustomStringConvertible {
    public typealias R = _R
    public let rows: Int
    public let cols: Int
    
    internal var grid: [R]
    
    // root initializer
    internal init(rows: Int, cols: Int, grid: [R]) {
        guard rows >= 0 && cols >= 0 else {
            fatalError("illegal matrix size (\(rows), \(cols))")
        }
        self.rows = rows
        self.cols = cols
        self.grid = grid
    }

    internal init(rows: Int, cols: Int, gen: (Int, Int) -> R) {
        let grid = (0 ..< rows * cols).map { (index: Int) -> R in
            let (i, j) = index /% cols
            return gen(i, j)
        }
        self.init(rows: rows, cols: cols, grid: grid)
    }

    public init(_ grid: R...) {
        if n.self == _TypeLooseSize.self || m.self == _TypeLooseSize.self {
            fatalError("attempted to initialize TypeLooseMatrix without specifying rows/cols.")
        }
        self.init(rows: n.value, cols: m.value, grid: grid)
    }
    
    public init(_ gen: (Int, Int) -> R) {
        if n.self == _TypeLooseSize.self || m.self == _TypeLooseSize.self {
            fatalError("attempted to initialize TypeLooseMatrix without specifying rows/cols.")
        }
        self.init(rows: n.value, cols: m.value, gen: gen)
    }
    
    public static var zero: Matrix<R, n, m> {
        return self.init { _ in 0 }
    }
}

// Matrix Operations

public extension Matrix {
    internal func gridIndex(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(index: Int) -> R {
        get { return grid[index] }
        set { grid[index] = newValue }
    }
    
    public subscript(i: Int, j: Int) -> R {
        get { return grid[gridIndex(i, j)] }
        set { grid[gridIndex(i, j)] = newValue }
    }
}

public func == <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Bool {
    return a.grid == b.grid
}

public func + <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
        return a[i, j] + b[i, j]
    }
}

public prefix func - <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
        return -a[i, j]
    }
}

public func - <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
        return a[i, j] - b[i, j]
    }
}

public func * <R: Ring, n: _Int, m: _Int>(r: R, a: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
        return r * a[i, j]
    }
}

public func * <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, r: R) -> Matrix<R, n, m> {
    return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
        return a[i, j] * r
    }
}

public func * <R: Ring, n: _Int, m: _Int, p: _Int>(a: Matrix<R, n, m>, b: Matrix<R, m, p>) -> Matrix<R, n, p> {
    #if USE_EIGEN
    if R.self == IntegerNumber.self, let aGrid = a.grid as? [IntegerNumber], let bGrid = b.grid as? [IntegerNumber] {
        var result = Array(repeating: 0, count: a.rows * b.cols)
        EigenLib.multiple(&result, a.rows, a.cols, b.cols, aGrid, bGrid)
        return Matrix<R, n, p>(rows: a.rows, cols: b.cols, grid: result.map{ $0 as! R })
    }
    #endif
    
    return Matrix<R, n, p>(rows: a.rows, cols: b.cols) { (i, k) -> R in
        return (0 ..< a.cols)
            .map({j in a[i, j] * b[j, k]})
            .reduce(0) {$0 + $1}
    }
}

public func ** <R: Ring, n: _Int>(a: Matrix<R, n, n>, k: Int) -> Matrix<R, n, n> {
    return k == 0 ? a.leftIdentity : a * (a ** (k - 1))
}

public typealias ColVector<R: Ring, n: _Int> = Matrix<R, n, _1>
public typealias RowVector<R: Ring, m: _Int> = Matrix<R, _1, m>

public extension Matrix {
    public func rowArray(_ i: Int) -> [R] {
        return (0 ..< cols).map{ j in self[i, j] }
    }
    
    public func colArray(_ j: Int) -> [R] {
        return (0 ..< rows).map{ i in self[i, j] }
    }
    
    public func rowVector(_ i: Int) -> RowVector<R, m> {
        return RowVector<R, m>(rows: 1, cols: cols){(_, j) -> R in
            return self[i, j]
        }
    }
    
    public func colVector(_ j: Int) -> ColVector<R, n> {
        return ColVector<R, n>(rows: rows, cols: 1){(i, _) -> R in
            return self[i, j]
        }
    }
    
    func toRowVectors() -> [RowVector<R, m>] {
        return (0 ..< rows).map { rowVector($0) }
    }
    
    func toColVectors() -> [ColVector<R, n>] {
        return (0 ..< cols).map { colVector($0) }
    }
    
    func submatrix<m0: _Int>(colsInRange c: CountableRange<Int>) -> Matrix<R, n, m0> {
        return Matrix<R, n, m0>(rows: self.rows, cols: c.upperBound - c.lowerBound) {
            self[$0, $1 + c.lowerBound]
        }
    }
    
    func submatrix<n0: _Int>(rowsInRange r: CountableRange<Int>) -> Matrix<R, n0, m> {
        return Matrix<R, n0, m>(rows: r.upperBound - r.lowerBound, cols: self.cols) {
            self[$0 + r.lowerBound, $1]
        }
    }
    
    func submatrix<n0: _Int, m0: _Int>(inRange: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> Matrix<R, n0, m0> {
        let (r, c) = inRange
        return Matrix<R, n0, m0>(rows: r.upperBound - r.lowerBound, cols: c.upperBound - c.lowerBound) {
            self[$0 + r.lowerBound, $1 + c.lowerBound]
        }
    }
    
    public var leftIdentity: Matrix<R, n, n> {
        return Matrix<R, n, n>(rows: rows, cols: rows) { $0 == $1 ? 1 : 0 }
    }
    
    public var rightIdentity: Matrix<R, m, m> {
        return Matrix<R, m, m>(rows: cols, cols: cols) { $0 == $1 ? 1 : 0 }
    }
    
    public var transposed: Matrix<R, m, n> {
        return Matrix<R, m, n>(rows: cols, cols: rows) { self[$1, $0] }
    }
}

// Elementary Matrix Operations (mutating)

public extension Matrix {
    public mutating func multiplyRow(at i0: Int, by r: R) {
        var p = UnsafeMutablePointer(&grid)
        p += gridIndex(i0, 0)
        
        for _ in 0 ..< cols {
            p.pointee = r * p.pointee
            p += 1
        }
    }
    
    public mutating func multiplyCol(at j0: Int, by r: R) {
        var p = UnsafeMutablePointer(&grid)
        p += gridIndex(0, j0)
        
        for _ in 0 ..< rows {
            p.pointee = r * p.pointee
            p += cols
        }
    }
    
    public mutating func addRow(at i0: Int, to i1: Int, multipliedBy r: R = 1) {
        var p0 = UnsafeMutablePointer(&grid)
        p0 += gridIndex(i0, 0)
        
        var p1 = UnsafeMutablePointer(&grid)
        p1 += gridIndex(i1, 0)
        
        for _ in 0 ..< cols {
            p1.pointee = p1.pointee + r * p0.pointee
            p0 += 1
            p1 += 1
        }
    }
    
    public mutating func addCol(at j0: Int, to j1: Int, multipliedBy r: R = 1) {
        var p0 = UnsafeMutablePointer(&grid)
        p0 += gridIndex(0, j0)
        
        var p1 = UnsafeMutablePointer(&grid)
        p1 += gridIndex(0, j1)
        
        for _ in 0 ..< rows {
            p1.pointee = p1.pointee + r * p0.pointee
            p0 += cols
            p1 += cols
        }
    }
    
    public mutating func swapRows(_ i0: Int, _ i1: Int) {
        var p0 = UnsafeMutablePointer(&grid)
        p0 += gridIndex(i0, 0)
        
        var p1 = UnsafeMutablePointer(&grid)
        p1 += gridIndex(i1, 0)
        
        for _ in 0 ..< cols {
            let a = p0.pointee
            p0.pointee = p1.pointee
            p1.pointee = a
            p0 += 1
            p1 += 1
        }
    }
    
    public mutating func swapCols(_ j0: Int, _ j1: Int) {
        var p0 = UnsafeMutablePointer(&grid)
        p0 += gridIndex(0, j0)
        
        var p1 = UnsafeMutablePointer(&grid)
        p1 += gridIndex(0, j1)
        
        for _ in 0 ..< rows {
            let a = p0.pointee
            p0.pointee = p1.pointee
            p1.pointee = a
            p0 += cols
            p1 += cols
        }
    }
}

// Matrix Elimination

public extension Matrix where R: EuclideanRing {
    public func eliminate(mode: MatrixEliminationMode = .Both) -> BaseMatrixElimination<R, n, m> {
        return R.matrixElimination(self, mode: mode)
    }
}

// SquareMatrix

public typealias SquareMatrix<R: Ring, n: _Int> = Matrix<R, n, n>

public extension Matrix where n == m {
    public static var identity: Matrix<R, n, n> {
        return self.init { $0 == $1 ? 1 : 0 }
    }
}

public extension Matrix where R: EuclideanRing, n == m {
    public var determinant: R {
        return self.eliminate().diagonal.reduce(R.identity) { $0 * $1 }
    }
}

// CustomStringConvertible

public extension Matrix {
    public var description: String {
        return "[" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joined(separator: ", ")
        }).joined(separator: "; ") + "]"
    }

    public var alignedDescription: String {
        return "[\t" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joined(separator: ",\t")
        }).joined(separator: "\n\t") + "]"
    }
    
    public static var symbol: String {
        return "M(\((n.self == _TypeLooseSize.self ? "?" : "\(n.value)")), \((m.self == _TypeLooseSize.self ? "?" : "\(m.value)")); \(R.symbol))"
    }
}

// Sequence / Iterator

public extension Matrix {
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
        guard current.0 < value.rows && current.1 < value.cols else {
            return nil
        }
        
        defer {
            switch current {
            case let c where c.1 + 1 >= value.cols:
                current = (c.0 + 1, 0)
            case let c:
                current = (c.0, c.1 + 1)
            }
        }
        
        return (value[current.0, current.1], current.0, current.1)
    }
}

// TypeLooseMatrix

public struct _TypeLooseSize : _Int { public static let value = 0 }
public typealias TypeLooseMatrix<R: Ring> = Matrix<R, _TypeLooseSize, _TypeLooseSize>

public extension Matrix where n == _TypeLooseSize, m == _TypeLooseSize {
    public init(_ rows: Int, _ cols: Int, _ grid: [R]) {
        self.init(rows: rows, cols: cols, grid: grid)
    }
    
    public init(_ rows: Int, _ cols: Int, _ gen: (Int, Int) -> R) {
        self.init(rows: rows, cols: cols, gen: gen)
    }
}
