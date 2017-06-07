import Foundation

private let Auto = -1

public typealias ColVector<R: Ring, n: _Int> = Matrix<R, n, _1>
public typealias RowVector<R: Ring, m: _Int> = Matrix<R, _1, m>
public typealias SquareMatrix<R: Ring, n: _Int> = Matrix<R, n, n>
public typealias DynamicMatrix<R: Ring> = Matrix<R, Dynamic, Dynamic>

public struct Matrix<_R: Ring, n: _Int, m: _Int>: _Matrix {
    public typealias R = _R
    public typealias Rows = n
    public typealias Cols = m
    
    public let rows: Int
    public let cols: Int
    public var grid: [R]
    
    // root initializer
    public init(rows: Int, cols: Int, grid: [R]) {
        assert(!(rows == Auto && n.self == Dynamic.self) && !(cols == Auto && m.self == Dynamic.self),
               "Must specify rows/cols for DynamicMatrix.")
        
        self.rows = (rows != Auto) ? rows : n.intValue
        self.cols = (cols != Auto) ? cols : m.intValue
        self.grid = grid
    }
    
    public init(rows: Int = Auto, cols: Int = Auto, gen: (Int, Int) -> R) {
        assert(!(rows == Auto && n.self == Dynamic.self) && !(cols == Auto && m.self == Dynamic.self),
               "Must specify rows/cols for DynamicMatrix.")
        
        let _rows = (rows != Auto) ? rows : n.intValue
        let _cols = (cols != Auto) ? cols : m.intValue
        
        let grid = (0 ..< _rows * _cols).map { (index: Int) -> R in
            let (i, j) = index /% _cols
            return gen(i, j)
        }
        self.init(rows: _rows, cols: _cols, grid: grid)
    }

    public init(_ grid: R...) {
        self.init(rows: Auto, cols: Auto, grid: grid)
    }
}

public protocol _Matrix: Module, Sequence {
    associatedtype Rows: _Int
    associatedtype Cols: _Int
    
    var rows: Int { get }
    var cols: Int { get }
    var grid: [R] { get set }
    
    init(rows: Int, cols: Int, grid: [R])
    init(rows: Int, cols: Int, gen: (Int, Int) -> R)
    
    subscript(i: Int, j: Int) -> R { get set }
}

public extension _Matrix {
    public static var zero: Self {
        return Self(rows: Auto, cols: Auto) { _ in 0 }
    }
    
    public static func == (a: Self, b: Self) -> Bool {
        return a.grid == b.grid
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return a[i, j] + b[i, j]
        }
    }
    
    public static prefix func - (a: Self) -> Self {
        return Self(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return -a[i, j]
        }
    }
    
    public static func - (a: Self, b: Self) -> Self {
        return Self(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return a[i, j] - b[i, j]
        }
    }
    
    public static func * (r: R, a: Self) -> Self {
        return Self(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return r * a[i, j]
        }
    }
    
    public static func * (a: Self, r: R) -> Self {
        return Self(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return a[i, j] * r
        }
    }
    
    public static func mul<B: _Matrix, C: _Matrix>(_ a: Self, _ b: B) -> C
        where Self.Rows == C.Rows, Self.Cols == B.Rows, B.Cols == C.Cols, Self.R == B.R, B.R == C.R {
            
        return C(rows: a.rows, cols: b.cols) { (i, k) -> R in
            return (0 ..< a.cols)
                .map({j in a[i, j] * b[j, k]})
                .reduce(0) {$0 + $1}
        }
    }
}

#if USE_EIGEN
public extension _Matrix where R == IntegerNumber {
    public static func mul<B: _Matrix, C: _Matrix>(_ a: Self, _ b: B) -> C
        where Self.Rows == C.Rows, Self.Cols == B.Rows, B.Cols == C.Cols, Self.R == B.R, B.R == C.R {
            
        var result = Array(repeating: 0, count: a.rows * b.cols)
        EigenLib.multiple(&result, a.rows, a.cols, b.cols, a.grid, b.grid)
        return C(rows: a.rows, cols: b.cols, grid: result)
    }
}
#endif

// Matrix Operations

public extension Matrix {
    internal func gridIndex(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(i: Int, j: Int) -> R {
        get { return grid[gridIndex(i, j)] }
        set { grid[gridIndex(i, j)] = newValue }
    }
    
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
    
    public static func * <p: _Int>(a: Matrix<R, n, m>, b: Matrix<R, m, p>) -> Matrix<R, n, p> {
        return Matrix<R, n, m>.mul(a, b)
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

// TODO use protocol extension
public extension Matrix where R: EuclideanRing {
    public func eliminate(mode: MatrixEliminationMode = .Both) -> BaseMatrixElimination<R, n, m> {
        return R.matrixElimination(self, mode: mode)
    }
}

// Convenient Initializers

public extension ColVector where Cols == _1 {
    public init(size: Int, elements: [R]) {
        self.init(rows: size, cols: 1, grid: elements)
    }
    
    public init(_ elements: R...) {
        self.init(size: elements.count, elements: elements)
    }
    
    public subscript(index: Int) -> R {
        get { return grid[index] }
        set { grid[index] = newValue }
    }
}

public extension RowVector where Rows == _1 {
    public init(size: Int, elements: [R]) {
        self.init(rows: 1, cols: size, grid: elements)
    }
    
    public init(_ elements: R...) {
        self.init(size: elements.count, elements: elements)
    }
    
    public subscript(index: Int) -> R {
        get { return grid[index] }
        set { grid[index] = newValue }
    }
}

// SquareMatrix

public extension Matrix where n == m {
    public static var identity: Matrix<R, n, n> {
        return self.init { $0 == $1 ? 1 : 0 }
    }
    
    public static func ** (a: Matrix<R, n, n>, k: Int) -> Matrix<R, n, n> {
        return k == 0 ? a.leftIdentity : a * (a ** (k - 1))
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
        return "M(\((n.self == Dynamic.self ? "?" : "\(n.intValue)")), \((m.self == Dynamic.self ? "?" : "\(m.intValue)")); \(R.symbol))"
    }
    
    public var hashValue: Int {
        return grid.count > 0 ? grid[0].hashValue : 0
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
