import Foundation

private let Auto = -1

public typealias ColVector<R: Ring, n: _Int>    = Matrix<R, n, _1>
public typealias RowVector<R: Ring, m: _Int>    = Matrix<R, _1, m>
public typealias SquareMatrix<R: Ring, n: _Int> = Matrix<R, n, n>
public typealias DynamicMatrix<R: Ring>         = Matrix<R, Dynamic, Dynamic>
public typealias DynamicColVector<R: Ring>      = Matrix<R, Dynamic, _1>
public typealias DynamicRowVector<R: Ring>      = Matrix<R, _1, Dynamic>

public struct Matrix<_R: Ring, n: _Int, m: _Int>: Module {
    public typealias R = _R
    
    internal let impl: _MatrixImpl<R>
    
    // root initializer
    private init(_ impl: _MatrixImpl<R>) {
        self.impl = impl
    }
    
    public init(rows r: Int = Auto, cols c: Int = Auto, grid: [R]) {
        let (rows, cols) = Matrix.determineSize(r, c, grid)
        let (l, required) = (grid.count, rows * cols)
        let grid = (l == required) ? grid :
                   (l >  required) ? Array(grid[0 ..< required]) :
                                     grid + Array(repeating: R.zero, count: required - l)
        
        self.init(R.matrixImplType.init(rows, cols, grid))
    }
    
    public init(rows r: Int = Auto, cols c: Int = Auto, gridGenerator g: (Int, Int) -> R) {
        let (rows, cols) = Matrix.determineSize(r, c, nil)
        let grid = (0 ..< rows * cols).map { (index: Int) -> R in
            let (i, j) = index /% cols
            return g(i, j)
        }
        
        self.init(R.matrixImplType.init(rows, cols, grid))
    }

    public init(_ grid: R...) {
        self.init(rows: Auto, cols: Auto, grid: grid)
    }
    
    private static func determineSize(_ rows: Int, _ cols: Int, _ grid: [R]?) -> (rows: Int, cols: Int) {
        func ceilDiv(_ a: Int, _ b: Int) -> Int {
            return (a + b - 1) / b
        }
        
        switch(n.self, m.self) {
            
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
    
    public var rows: Int { return impl.rows }
    public var cols: Int { return impl.cols }
    
    public subscript(i: Int, j: Int) -> R {
        get { return impl[i, j] }
        set { impl[i, j] = newValue }
    }
    
    public static var zero: Matrix<_R, n, m> {
        return Matrix<R, n, m> { _,_ in 0 }
    }
    
    public static func ==(a: Matrix<_R, n, m>, b: Matrix<_R, n, m>) -> Bool {
        return a.impl.equals(b.impl)
    }
    
    public static func +(a: Matrix<_R, n, m>, b: Matrix<_R, n, m>) -> Matrix<_R, n, m> {
        return Matrix(a.impl.add(b.impl))
    }
    
    public prefix static func -(a: Matrix<_R, n, m>) -> Matrix<_R, n, m> {
        return Matrix(a.impl.negate())
    }
    
    public static func *(r: _R, a: Matrix<_R, n, m>) -> Matrix<_R, n, m> {
        return Matrix(a.impl.leftMul(r))
    }
    
    public static func *(a: Matrix<_R, n, m>, r: _R) -> Matrix<_R, n, m> {
        return Matrix(a.impl.rightMul(r))
    }
    
    public static func * <p: _Int>(a: Matrix<_R, n, m>, b: Matrix<_R, m, p>) -> Matrix<_R, n, p> {
        return Matrix<_R, n, p>(a.impl.mul(b.impl))
    }
    
    public var transposed: Matrix<R, m, n> {
        return Matrix<R, m, n>(impl.transpose())
    }
    
    public var leftIdentity: Matrix<R, n, n> {
        return Matrix<R, n, n>(impl.leftIdentity())
    }
    
    public var rightIdentity: Matrix<R, m, m> {
        return Matrix<R, m, m>(impl.rightIdentity())
    }
    
    public func rowArray(_ i: Int) -> [R] {
        return impl.rowArray(i)
    }
    
    public func colArray(_ j: Int) -> [R] {
        return impl.colArray(j)
    }
    
    public func rowVector(_ i: Int) -> RowVector<R, m> {
        return RowVector(impl.rowVector(i))
    }
    
    public func colVector(_ j: Int) -> ColVector<R, n> {
        return ColVector(impl.colVector(j))
    }
    
    public func toRowVectors() -> [RowVector<R, m>] {
        return (0 ..< cols).map{ rowVector($0) }
    }
    
    public func toColVectors() -> [ColVector<R, n>] {
        return (0 ..< rows).map{ colVector($0) }
    }
    
    public func submatrix<k: _Int>(colsInRange c: CountableRange<Int>) -> Matrix<R, n, k> {
        return Matrix<R, n, k>(impl.submatrix(colsInRange: c))
    }
    
    public func submatrix<k: _Int>(rowsInRange r: CountableRange<Int>) -> Matrix<R, k, m> {
        return Matrix<R, k, m>(impl.submatrix(rowsInRange: r))
    }
    
    public func submatrix<k: _Int, l: _Int>(inRange range: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> Matrix<R, k, l> {
        return Matrix<R, k, l>(impl.submatrix(inRange: range))
    }
    
    public mutating func multiplyRow(at i0: Int, by r: R) {
        impl.multiplyRow(at: i0, by: r)
    }
    
    public mutating func multiplyCol(at j0: Int, by r: R) {
        impl.multiplyCol(at: j0, by: r)
    }
    
    public mutating func addRow(at i0: Int, to i1: Int, multipliedBy r: R = 1) {
        impl.addRow(at: i0, to: i1, multipliedBy: r)
    }
    
    public mutating func addCol(at j0: Int, to j1: Int, multipliedBy r: R = 1) {
        impl.addCol(at: j0, to: j1, multipliedBy: r)
    }
    
    public mutating func swapRows(_ i0: Int, _ i1: Int) {
        impl.swapRows(i0, i1)
    }
    
    public mutating func swapCols(_ j0: Int, _ j1: Int) {
        impl.swapCols(j0, j1)
    }
    
    public func eliminate(mode: MatrixEliminationMode = .Both) -> BaseMatrixElimination<R, n, m> {
        fatalError("MatrixElimination is not impled for \(R.self).")
    }
    
    public var hashValue: Int {
        return 0 // TODO
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
        return "M(\((n.self == Dynamic.self ? "?" : "\(n.intValue)")), \((m.self == Dynamic.self ? "?" : "\(m.intValue)")); \(R.symbol))"
    }
}

public extension Matrix where m == _1 {
    public subscript(index: Int) -> R {
        get { return self[index, 0] }
        set { self[index, 0] = newValue }
    }
}

public extension Matrix where n == _1 {
    public subscript(index: Int) -> R {
        get { return self[0, index] }
        set { self[0, index] = newValue }
    }
}

// TODO: conform to Ring after conditional conformance is supported.
public extension Matrix where n == m {
    public static var identity: Matrix<R, n, n> {
        return Matrix<R, n, n>(rows: Auto, cols: Auto) { $0 == $1 ? 1 : 0 }
    }
    
    public static func ** (a: Matrix<R, n, n>, k: Int) -> Matrix<R, n, n> {
        return k == 0 ? a.leftIdentity : a * (a ** (k - 1))
    }
}

// MatrixIterator
/*
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
*/
