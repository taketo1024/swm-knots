import Foundation

private let Auto = -1

public typealias ColVector<R: Ring, n: _Int>    = Matrix<R, n, _1>
public typealias RowVector<R: Ring, m: _Int>    = Matrix<R, _1, m>
public typealias SquareMatrix<R: Ring, n: _Int> = Matrix<R, n, n>
public typealias DynamicMatrix<R: Ring>         = Matrix<R, Dynamic, Dynamic>
public typealias DynamicColVector<R: Ring>      = Matrix<R, Dynamic, _1>
public typealias DynamicRowVector<R: Ring>      = Matrix<R, _1, Dynamic>

public struct Matrix<_R: Ring, n: _Int, m: _Int>: _Matrix {
    public typealias R = _R
    public typealias Rows = n
    public typealias Cols = m
    
    public let rows: Int
    public let cols: Int
    public var grid: [R]
    
    // root initializer
    public init(rows r: Int = Auto, cols c: Int = Auto, grid: [R]) {
        let (rows, cols) = Matrix.determineSize(r, c, grid)
        
        self.rows = rows
        self.cols = cols
        
        let (l, required) = (grid.count, rows * cols)
        self.grid = (l == required) ? grid :
                    (l >  required) ? Array(grid[0 ..< required]) :
                                      (grid + Array(repeating: R.zero, count: required - l))
    }
    
    public init(rows r: Int = Auto, cols c: Int = Auto, gridGenerator g: (Int, Int) -> R) {
        let (rows, cols) = Matrix.determineSize(r, c, nil)
        
        let grid = (0 ..< rows * cols).map { (index: Int) -> R in
            let (i, j) = index /% cols
            return g(i, j)
        }
        
        self.rows = rows
        self.cols = cols
        self.grid = grid
    }

    public init(_ grid: R...) {
        self.init(rows: Auto, cols: Auto, grid: grid)
    }
    
    private static func determineSize(_ rows: Int, _ cols: Int, _ grid: [R]?) -> (rows: Int, cols: Int) {
        func ceilDiv(_ a: Int, _ b: Int) -> Int {
            return (a + b - 1) / b
        }
        
        switch(Rows.self, Cols.self) {
            
        // completely determined by type.
        case let (R, C) where !(R is Dynamic.Type) && !(C is Dynamic.Type):
            assert(rows == Auto || rows == R.intValue, "rows mismatch with type-parameter: \(rows) != \(R.intValue)")
            assert(cols == Auto || cols == C.intValue, "cols mismatch with type-parameter: \(cols) != \(C.intValue)")
            return (R.intValue, C.intValue)
            
        // rows is determined by type.
        case let (R, C) where !(R is Dynamic.Type) && (C is Dynamic.Type):
            assert(rows == Auto || rows == R.intValue, "rows mismatch with type-parameter: \(rows) != \(R.intValue)")
            let r = R.intValue
            switch (cols, grid) {
            case let (c, _) where c != Auto:
                return (r, c)
            case let (c, g?) where r > 0 && c == Auto:
                return (r, ceilDiv(g.count, r))
            default:
                fatalError("Matrix size indeterminable.")
            }
            
        // cols is determined by type.
        case let (R, C) where (R is Dynamic.Type) && !(C is Dynamic.Type):
            assert(cols == Auto || cols == C.intValue, "cols mismatch with type-parameter: \(cols) != \(C.intValue)")
            let c = C.intValue
            switch (rows, grid) {
            case let (r, _) where r != Auto:
                return (r, c)
            case let (r, g?) where r == Auto && c > 0:
                return (ceilDiv(g.count, c), c)
            default:
                fatalError("Matrix size indeterminable.")
            }
            
        // rows, cols are dynamic.
        case let (R, C) where  (R is Dynamic.Type) &&  (C is Dynamic.Type):
            switch (rows, cols, grid) {
            case let (r, c, _) where r != Auto && c != Auto:
                return (r, c)
            case let (r, _, g?) where r != Auto && r > 0:
                return (r, ceilDiv(g.count, r))
            case let (_, c, g?) where c != Auto && c > 0:
                return (ceilDiv(g.count, c), c)
            default:
                fatalError("Matrix size indeterminable.")
            }
            
        default:
            fatalError()
        }
    }
}

// Details implemented by protocol extension to enable polymorphism.

public protocol _Matrix: Module, Sequence {
    associatedtype Rows: _Int
    associatedtype Cols: _Int
    typealias Iterator = MatrixIterator<Self>
    
    var rows: Int { get }
    var cols: Int { get }
    var grid: [R] { get set }
    
    init(rows: Int, cols: Int, grid: [R])
    init(rows: Int, cols: Int, gridGenerator g: (Int, Int) -> R)
    
    subscript(i: Int, j: Int) -> R { get set }
    func gridIndex(_ i: Int, _ j: Int) -> Int
    
    var transposed:    Matrix<R, Cols, Rows> { get }
    var leftIdentity:  Matrix<R, Rows, Rows> { get }
    var rightIdentity: Matrix<R, Cols, Cols> { get }
    
    func rowArray(_ i: Int) -> [R]
    func colArray(_ j: Int) -> [R]
    func rowVector(_ i: Int) -> RowVector<R, Cols>
    func colVector(_ j: Int) -> ColVector<R, Rows>
    func toRowVectors() -> [RowVector<R, Cols>]
    func toColVectors() -> [ColVector<R, Rows>]
    func submatrix<SubCols: _Int>(colsInRange c: CountableRange<Int>) -> Matrix<R, Rows, SubCols>
    func submatrix<SubRows: _Int>(rowsInRange r: CountableRange<Int>) -> Matrix<R, SubRows, Cols>
    func submatrix<SubRows: _Int, SubCols: _Int>(inRange: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> Matrix<R, SubRows, SubCols>
    
    mutating func multiplyRow(at i0: Int, by r: R)
    mutating func multiplyCol(at j0: Int, by r: R)
    mutating func addRow(at i0: Int, to i1: Int, multipliedBy r: R)
    mutating func addCol(at j0: Int, to j1: Int, multipliedBy r: R)
    mutating func swapRows(_ i0: Int, _ i1: Int)
    mutating func swapCols(_ j0: Int, _ j1: Int)
}

public extension _Matrix {
    public func gridIndex(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(i: Int, j: Int) -> R {
        get { return grid[gridIndex(i, j)] }
        set { grid[gridIndex(i, j)] = newValue }
    }
    
    public func makeIterator() -> MatrixIterator<Self> {
        return MatrixIterator(self)
    }
    
    public static var zero: Self {
        return Self(rows: Auto, cols: Auto) { _ in 0 }
    }
    
    public static func == (a: Self, b: Self) -> Bool {
        assert((a.rows, a.cols) == (b.rows, b.cols), "Mismatching matrix size.")
        return a.grid == b.grid
    }
    
    public static func + (a: Self, b: Self) -> Self {
        assert((a.rows, a.cols) == (b.rows, b.cols), "Mismatching matrix size.")
        return Self(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return a[i, j] + b[i, j]
        }
    }
    
    public static prefix func - (a: Self) -> Self {
        return Self(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return -a[i, j]
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
    
    public static func * <n: _Int, m: _Int>(_ a: Self, _ b: Matrix<R, n, m>) -> Matrix<R, Self.Rows, m> where Self.Cols == n {
        assert(a.cols == b.rows, "Mismatching matrix size.")
        return Matrix<R, Self.Rows, m> (rows: a.rows, cols: b.cols) { (i, k) -> R in
            return (0 ..< a.cols)
                .map({j in a[i, j] * b[j, k]})
                .reduce(0) {$0 + $1}
        }
    }
    
    public var transposed: Matrix<R, Cols, Rows> {
        return Matrix<R, Cols, Rows>(rows: cols, cols: rows) { self[$1, $0] }
    }
    
    public var leftIdentity: Matrix<R, Rows, Rows> {
        return Matrix<R, Rows, Rows>(rows: rows, cols: rows) { $0 == $1 ? 1 : 0 }
    }
    
    public var rightIdentity: Matrix<R, Cols, Cols> {
        return Matrix<R, Cols, Cols>(rows: cols, cols: cols) { $0 == $1 ? 1 : 0 }
    }
    
    public func rowArray(_ i: Int) -> [R] {
        return (0 ..< cols).map{ j in self[i, j] }
    }
    
    public func colArray(_ j: Int) -> [R] {
        return (0 ..< rows).map{ i in self[i, j] }
    }
    
    public func rowVector(_ i: Int) -> RowVector<R, Cols> {
        return RowVector<R, Cols>(rows: 1, cols: cols){(_, j) -> R in
            return self[i, j]
        }
    }
    
    public func colVector(_ j: Int) -> ColVector<R, Rows> {
        return ColVector<R, Rows>(rows: rows, cols: 1){(i, _) -> R in
            return self[i, j]
        }
    }
    
    public func toRowVectors() -> [RowVector<R, Cols>] {
        return (0 ..< rows).map { rowVector($0) }
    }
    
    public func toColVectors() -> [ColVector<R, Rows>] {
        return (0 ..< cols).map { colVector($0) }
    }
    
    public func submatrix<SubCols: _Int>(colsInRange c: CountableRange<Int>) -> Matrix<R, Rows, SubCols> {
        return Matrix<R, Rows, SubCols>(rows: self.rows, cols: c.upperBound - c.lowerBound) {
            self[$0, $1 + c.lowerBound]
        }
    }
    
    public func submatrix<SubRows: _Int>(rowsInRange r: CountableRange<Int>) -> Matrix<R, SubRows, Cols> {
        return Matrix<R, SubRows, Cols>(rows: r.upperBound - r.lowerBound, cols: self.cols) {
            self[$0 + r.lowerBound, $1]
        }
    }
    
    public func submatrix<SubRows: _Int, SubCols: _Int>(inRange: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> Matrix<R, SubRows, SubCols> {
        let (r, c) = inRange
        return Matrix<R, SubRows, SubCols>(rows: r.upperBound - r.lowerBound, cols: c.upperBound - c.lowerBound) {
            self[$0 + r.lowerBound, $1 + c.lowerBound]
        }
    }
    
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
    
    public var hashValue: Int {
        return grid.count > 0 ? grid[0].hashValue : 0
    }
    
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
        return "M(\((Rows.self == Dynamic.self ? "?" : "\(Rows.intValue)")), \((Cols.self == Dynamic.self ? "?" : "\(Cols.intValue)")); \(R.symbol))"
    }
}

public extension _Matrix where Cols == _1 {
    public subscript(index: Int) -> R {
        get { return grid[index] }
        set { grid[index] = newValue }
    }
}

public extension _Matrix where Rows == _1 {
    public subscript(index: Int) -> R {
        get { return grid[index] }
        set { grid[index] = newValue }
    }
}

// TODO: conform to Ring after conditional conformance is supported.

public extension _Matrix where Rows == Cols {
    public static var identity: Self {
        return Self(rows: Auto, cols: Auto) { $0 == $1 ? 1 : 0 }
    }
    
    public static func ** (a: Self, k: Int) -> Matrix<R, Rows, Rows> {
        return k == 0 ? a.leftIdentity : a * (a ** (k - 1))
    }
}

// TODO use protocol extension

public extension Matrix where R: EuclideanRing {
    public func eliminate(mode: MatrixEliminationMode = .Both) -> BaseMatrixElimination<R, n, m> {
        return R.matrixElimination(self, mode: mode)
    }
}

public extension Matrix where R: EuclideanRing, n == m {
    public var determinant: R {
        return self.eliminate().diagonal.reduce(R.identity) { $0 * $1 }
    }
}

#if USE_EIGEN
public extension _Matrix where R == IntegerNumber {
    public static func * <n: _Int, m: _Int>(_ a: Self, _ b: Matrix<R, n, m>) -> Matrix<R, Self.Rows, m> where Self.Cols == n {
        var result = Array(repeating: 0, count: a.rows * b.cols)
        EigLib.multiple(&result, a.rows, a.cols, b.cols, a.grid, b.grid)
        return Matrix<R, Rows, m>(rows: a.rows, cols: b.cols, grid: result)
    }
}
#endif

// MatrixIterator

public struct MatrixIterator<M: _Matrix> : IteratorProtocol {
    private let value: M
    private var current = (0, 0)
    
    public init(_ value: M) {
        self.value = value
    }
    
    mutating public func next() -> (value: M.R, row: Int, col: Int)? {
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
