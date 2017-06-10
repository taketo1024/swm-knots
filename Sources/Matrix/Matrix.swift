import Foundation

public typealias ColVector<R: Ring, n: _Int>    = Matrix<R, n, _1>
public typealias RowVector<R: Ring, m: _Int>    = Matrix<R, _1, m>
public typealias SquareMatrix<R: Ring, n: _Int> = Matrix<R, n, n>
public typealias DynamicMatrix<R: Ring>         = Matrix<R, Dynamic, Dynamic>
public typealias DynamicColVector<R: Ring>      = Matrix<R, Dynamic, _1>
public typealias DynamicRowVector<R: Ring>      = Matrix<R, _1, Dynamic>

public enum MatrixType {
    case Default
    case Sparse
}

public typealias MatrixComponent<R> = (row: Int, col: Int, value: R)

public struct Matrix<_R: Ring, n: _Int, m: _Int>: Module, Sequence {
    public typealias R = _R
    public typealias Iterator = MatrixIterator<R, n, m>
    
    public let type: MatrixType
    internal var impl: _MatrixImpl<R>
    
    // internal root initializer
    internal init(_ type: MatrixType, _ impl: _MatrixImpl<R>) {
        self.type = type
        self.impl = impl
    }
    
    // 1. Initialize by Grid (simple but ineffective).
    public init(rows r: Int? = nil, cols c: Int? = nil, type t: MatrixType = .Default, grid: [R]) {
        let (rows, cols) = Matrix.determineSize(r, c, grid)
        self.init(t, R.matrixImplType(t).init(rows, cols, grid))
        
        /*
        let n = grid.count
        let g: (Int, Int) -> R = { (i, j) -> R in
            let index = i * cols + j
            return (index < n) ? grid[index] : R.zero
        }
        */
    }
    
    // 2. Initialize by Generator.
    public init(rows r: Int? = nil, cols c: Int? = nil, type t: MatrixType = .Default, generator g: (Int, Int) -> R) {
        let (rows, cols) = Matrix.determineSize(r, c, nil)
        self.init(t, R.matrixImplType(t).init(rows, cols, g))
    }
    
    // 3. Initialize by Components (good for Sparce Matrix).
    public init(rows r: Int? = nil, cols c: Int? = nil, type t: MatrixType = .Default, components: [MatrixComponent<R>]) {
        let (rows, cols) = Matrix.determineSize(r, c, nil)
        self.init(t, R.matrixImplType(t).init(rows, cols, components))
    }
    
    // Convenience initializer of 1.
    public init(_ grid: R...) {
        self.init(grid: grid)
    }
    
    private static func determineSize(_ rows: Int?, _ cols: Int?, _ grid: [R]?) -> (rows: Int, cols: Int) {
        func ceilDiv(_ a: Int, _ b: Int) -> Int {
            return (a + b - 1) / b
        }
        
        switch(n.self, m.self) {
            
        // completely determined by type.
        case let (R, C) where !(R is Dynamic.Type) && !(C is Dynamic.Type):
            assert(rows == nil || rows! == R.intValue, "rows mismatch with type-parameter: \(String(describing: rows)) != \(R.intValue)")
            assert(cols == nil || cols! == C.intValue, "cols mismatch with type-parameter: \(String(describing: cols)) != \(C.intValue)")
            return (R.intValue, C.intValue)
            
        // rows is determined by type.
        case let (R, C) where !(R is Dynamic.Type) && (C is Dynamic.Type):
            assert(rows == nil || rows! == R.intValue, "rows mismatch with type-parameter: \(String(describing: rows)) != \(R.intValue)")
            let r = R.intValue
            switch (cols, grid) {
            case let (c?, _):
                return (r, c)
            case let (nil, g?) where r > 0:
                return (r, ceilDiv(g.count, r))
            default:
                fatalError("Matrix size indeterminable.")
            }
            
        // cols is determined by type.
        case let (R, C) where (R is Dynamic.Type) && !(C is Dynamic.Type):
            assert(cols == nil || cols == C.intValue, "cols mismatch with type-parameter: \(String(describing: cols)) != \(C.intValue)")
            let c = C.intValue
            switch (rows, grid) {
            case let (r?, _):
                return (r, c)
            case let (nil, g?) where c > 0:
                return (ceilDiv(g.count, c), c)
            default:
                fatalError("Matrix size indeterminable.")
            }
            
        // rows, cols are dynamic.
        case let (R, C) where  (R is Dynamic.Type) &&  (C is Dynamic.Type):
            switch (rows, cols, grid) {
            case let (r?, c?, _):
                return (r, c)
            case let (r?, _, g?) where r > 0:
                return (r, ceilDiv(g.count, r))
            case let (_, c?, g?) where c > 0:
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
    
    private mutating func copyIfNecessary() {
        if !isKnownUniquelyReferenced(&impl) {
            print("copied!")
            impl = impl.copy()
        }
    }
    
    public subscript(i: Int, j: Int) -> R {
        get { return impl[i, j] }
        set {
            copyIfNecessary()
            impl[i, j] = newValue
        }
    }
    
    public func makeIterator() -> MatrixIterator<R, n, m> {
        return MatrixIterator(self)
    }
    
    public static var zero: Matrix<R, n, m> {
        return Matrix<R, n, m> { _,_ in 0 }
    }
    
    public static func ==(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Bool {
        return a.impl.equals(b.impl)
    }
    
    public static func +(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Matrix<R, n, m> {
        return Matrix(a.type, a.impl.add(b.impl))
    }
    
    public prefix static func -(a: Matrix<R, n, m>) -> Matrix<R, n, m> {
        return Matrix(a.type, a.impl.negate())
    }
    
    public static func *(r: R, a: Matrix<R, n, m>) -> Matrix<R, n, m> {
        return Matrix(a.type, a.impl.leftMul(r))
    }
    
    public static func *(a: Matrix<R, n, m>, r: R) -> Matrix<R, n, m> {
        return Matrix(a.type, a.impl.rightMul(r))
    }
    
    public static func * <p: _Int>(a: Matrix<R, n, m>, b: Matrix<R, m, p>) -> Matrix<R, n, p> {
        return Matrix<R, n, p>(a.type, a.impl.mul(b.impl))
    }
    
    public var transposed: Matrix<R, m, n> {
        return Matrix<R, m, n>(type, impl.transpose())
    }
    
    public var leftIdentity: Matrix<R, n, n> {
        return Matrix<R, n, n>(type, impl.leftIdentity())
    }
    
    public var rightIdentity: Matrix<R, m, m> {
        return Matrix<R, m, m>(type, impl.rightIdentity())
    }
    
    // TODO delete if possible
    public func rowArray(_ i: Int) -> [R] {
        return rowVector(i).map{ c in c.value }
    }
    
    public func colArray(_ j: Int) -> [R] {
        return colVector(j).map{ c in c.value }
    }
    // --TODO
    
    public func rowVector(_ i: Int) -> RowVector<R, m> {
        return RowVector(type, impl.rowVector(i))
    }
    
    public func colVector(_ j: Int) -> ColVector<R, n> {
        return ColVector(type, impl.colVector(j))
    }
    
    public func toRowVectors() -> [RowVector<R, m>] {
        return (0 ..< rows).map{ rowVector($0) }
    }
    
    public func toColVectors() -> [ColVector<R, n>] {
        return (0 ..< cols).map{ colVector($0) }
    }
    
    public func submatrix<k: _Int>(rowsInRange r: CountableRange<Int>) -> Matrix<R, k, m> {
        return Matrix<R, k, m>(type, impl.submatrix(rowsInRange: r))
    }
    
    public func submatrix<k: _Int>(colsInRange c: CountableRange<Int>) -> Matrix<R, n, k> {
        return Matrix<R, n, k>(type, impl.submatrix(colsInRange: c))
    }
    
    public func submatrix<k: _Int, l: _Int>(inRange range: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> Matrix<R, k, l> {
        return Matrix<R, k, l>(type, impl.submatrix(inRange: range))
    }
    
    public mutating func multiplyRow(at i0: Int, by r: R) {
        copyIfNecessary()
        impl.multiplyRow(at: i0, by: r)
    }
    
    public mutating func multiplyCol(at j0: Int, by r: R) {
        copyIfNecessary()
        impl.multiplyCol(at: j0, by: r)
    }
    
    public mutating func addRow(at i0: Int, to i1: Int, multipliedBy r: R = 1) {
        copyIfNecessary()
        impl.addRow(at: i0, to: i1, multipliedBy: r)
    }
    
    public mutating func addCol(at j0: Int, to j1: Int, multipliedBy r: R = 1) {
        copyIfNecessary()
        impl.addCol(at: j0, to: j1, multipliedBy: r)
    }
    
    public mutating func swapRows(_ i0: Int, _ i1: Int) {
        copyIfNecessary()
        impl.swapRows(i0, i1)
    }
    
    public mutating func swapCols(_ j0: Int, _ j1: Int) {
        copyIfNecessary()
        impl.swapCols(j0, j1)
    }
    
    public var hashValue: Int {
        return 0 // TODO
    }
    
    public var description: String {
        return impl.description
    }
    
    public var alignedDescription: String {
        return impl.alignedDescription
    }
    
    public static var symbol: String {
        return "M(\((n.self == Dynamic.self ? "?" : "\(n.intValue)")), \((m.self == Dynamic.self ? "?" : "\(m.intValue)")); \(R.symbol))"
    }
}

public extension Matrix where R: EuclideanRing {
    public func eliminate(mode: MatrixEliminationMode = .Both) -> MatrixElimination<R, n, m> {
        return MatrixElimination(self, mode, R.matrixEliminationProcessorType())
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
    public var determinant: R {
        return impl.determinant()
    }
    
    public static var identity: Matrix<R, n, n> {
        return Matrix<R, n, n> { $0 == $1 ? 1 : 0 }
    }
    
    public static func ** (a: Matrix<R, n, n>, k: Int) -> Matrix<R, n, n> {
        return k == 0 ? a.leftIdentity : a * (a ** (k - 1))
    }
}

// MatrixIterator
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
