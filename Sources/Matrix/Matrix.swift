import Foundation

public typealias ColVector<n: _Int, R: Ring>    = Matrix<n, _1, R>
public typealias RowVector<m: _Int, R: Ring>    = Matrix<_1, m, R>
public typealias SquareMatrix<n: _Int, R: Ring> = Matrix<n, n, R>
public typealias DynamicMatrix<R: Ring>         = Matrix<Dynamic, Dynamic, R>
public typealias DynamicColVector<R: Ring>      = Matrix<Dynamic, _1, R>
public typealias DynamicRowVector<R: Ring>      = Matrix<_1, Dynamic, R>

public enum MatrixType {
    case Default
    case Sparse
}

public typealias MatrixComponent<R> = (row: Int, col: Int, value: R)

public struct Matrix<n: _Int, m: _Int, R: Ring>: Module, Sequence {
    public typealias CoeffRing = R
    public typealias Iterator = MatrixIterator<n, m, R>
    
    public let rows: Int
    public let cols: Int
    public let type: MatrixType
    
    public var grid: [R]
    
    internal var smithNormalFormCache: Cache<MatrixEliminator<n, m, R>> = Cache()
    internal func clearCache() {
        smithNormalFormCache.value = nil
    }

    // Root Initializer.
    @_inlineable
    public init(_ rows: Int, _ cols: Int, _ type: MatrixType, _ grid: [R]) {
        self.rows = rows
        self.cols = cols
        self.type = type
        self.grid = grid
    }
    
    // 1. Initialize by Grid.
    public init(rows r: Int? = nil, cols c: Int? = nil, type: MatrixType = .Default, grid: [R]) {
        let (rows, cols) = Matrix.determineSize(r, c)
        self.init(rows, cols, type, grid)
    }
    
    // 2. Initialize by Generator.
    public init(rows r: Int? = nil, cols c: Int? = nil, type: MatrixType = .Default, generator g: (Int, Int) -> R) {
        let (rows, cols) = Matrix.determineSize(r, c)
        let grid = (0 ..< rows * cols).map { (index: Int) -> R in
            let (i, j) = index /% cols
            return g(i, j)
        }
        self.init(rows, cols, type, grid)
    }
    
    // 3. Initialize by Components.
    public init(rows r: Int? = nil, cols c: Int? = nil, type: MatrixType = .Default, components: [MatrixComponent<R>]) {
        let (rows, cols) = Matrix.determineSize(r, c)
        var grid = Array(repeating: R.zero, count: rows * cols)
        for (i, j, a) in components {
            grid[(i * cols) + j] = a
        }
        self.init(rows, cols, type, grid)
    }
    
    // Convenience Initializer 1.
    public init(rows r: Int? = nil, cols c: Int? = nil, type: MatrixType = .Default, _ grid: R...) {
        let (rows, cols) = Matrix.determineSize(r, c)

        let l = n.intValue * m.intValue
        if grid.count == l {
            self.init(rows, cols, type, grid)
        } else if grid.count < l {
            self.init(rows, cols, type, grid + Array(repeating: R.zero, count: l - grid.count))
        } else {
            self.init(rows, cols, type, grid[0 ..< l].toArray() )
        }
    }
    
    // Convenience Initializer 2.
    public init(rows r: Int? = nil, cols c: Int? = nil, type: MatrixType = .Default, fill: R = R.zero) {
        let (rows, cols) = Matrix.determineSize(r, c)
        let grid = Array(repeating: fill, count: rows * cols)
        self.init(rows, cols, type, grid)
    }
    
    // Convenience Initializer 3.
    public init(rows r: Int? = nil, cols c: Int? = nil, type: MatrixType = .Default, diagonal: [R]) {
        let (rows, cols) = Matrix.determineSize(r, c)
        var grid = Array(repeating: R.zero, count: rows * cols)
        for (i, a) in diagonal.enumerated() {
            grid[(i * cols) + i] = a
        }
        self.init(rows, cols, type, grid)
    }
    
    @_transparent
    public func gridIndex(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(i: Int, j: Int) -> R {
        @_transparent
        get { return grid[gridIndex(i, j)] }
        
        @_transparent
        set { grid[gridIndex(i, j)] = newValue }
    }
    
    public func makeIterator() -> MatrixIterator<n, m, R> {
        return MatrixIterator(self)
    }
    
    public static var zero: Matrix<n, m, R> {
        return Matrix<n, m, R> { _,_ in 0 }
    }
    
    public static func ==(a: Matrix<n, m, R>, b: Matrix<n, m, R>) -> Bool {
        assert((a.rows, a.cols) == (b.rows, b.cols), "Mismatching matrix size.")
        return a.grid == b.grid
    }
    
    public static func +(a: Matrix<n, m, R>, b: Matrix<n, m, R>) -> Matrix<n, m, R> {
        assert((a.rows, a.cols) == (b.rows, b.cols), "Mismatching matrix size.")
        
        let type = (a.type == b.type) ? a.type : .Default
        let grid = (0 ..< a.grid.count).map { a.grid[$0] + b.grid[$0] }
        return Matrix(a.rows, a.cols, type, grid)
    }
    
    public prefix static func -(a: Matrix<n, m, R>) -> Matrix<n, m, R> {
        let grid = a.grid.map { -$0 }
        return Matrix(a.rows, a.cols, a.type, grid)
    }
    
    public static func *(r: R, a: Matrix<n, m, R>) -> Matrix<n, m, R> {
        let grid = a.grid.map { r * $0 }
        return Matrix(a.rows, a.cols, a.type, grid)
    }
    
    public static func *(a: Matrix<n, m, R>, r: R) -> Matrix<n, m, R> {
        let grid = a.grid.map { $0 * r }
        return Matrix(a.rows, a.cols, a.type, grid)
    }
    
    @_inlineable
    @_specialize(where R==Int, n==Dynamic, m==Dynamic, p==Dynamic)
    public static func * <p>(a: Matrix<n, m, R>, b: Matrix<m, p, R>) -> Matrix<n, p, R> {
        assert(a.cols == b.rows, "Mismatching matrix size.")
        
        let type = (a.type == b.type) ? a.type : .Default
        let grid = (0 ..< a.rows * b.cols).map { (index) -> R in
            let (i, k) = (index / b.cols, index % b.cols)
            return (0 ..< a.cols).sum { j in a[i, j] * b[j, k] }
        }
        
        return Matrix<n, p, R>(a.rows, b.cols, type, grid)
    }
    
    public var transposed: Matrix<m, n, R> {
        return Matrix<m, n, R>(rows: cols, cols: rows, type: type) { (i, j) -> R in
            return self[j, i]
        }
    }
    
    // TODO delete if possible
    public var leftIdentity: Matrix<n, n, R> {
        return Matrix<n, n, R>(rows: rows, cols: rows, type: type) { $0 == $1 ? 1 : 0 }
    }
    
    public var rightIdentity: Matrix<m, m, R> {
        return Matrix<m, m, R>(rows: cols, cols: cols, type: type) { $0 == $1 ? 1 : 0 }
    }
    // --TODO

    public func rowArray(_ i: Int) -> [R] {
        return rowVector(i).map{ c in c.value }
    }
    
    public func colArray(_ j: Int) -> [R] {
        return colVector(j).map{ c in c.value }
    }
    
    public func rowVector(_ i: Int) -> RowVector<m, R> {
        return submatrix(inRange: (i ..< i + 1, 0 ..< cols))
    }
    
    public func colVector(_ j: Int) -> ColVector<n, R> {
        return submatrix(inRange: (0 ..< rows, j ..< j + 1))
    }
    
    public func toRowVectors() -> [RowVector<m, R>] {
        return (0 ..< rows).map{ rowVector($0) }
    }
    
    public func toColVectors() -> [ColVector<n, R>] {
        return (0 ..< cols).map{ colVector($0) }
    }
    
    public func submatrix<k: _Int>(rowsInRange r: CountableRange<Int>) -> Matrix<k, m, R> {
        return submatrix(inRange: (r, 0 ..< cols))
    }
    
    public func submatrix<k: _Int>(colsInRange c: CountableRange<Int>) -> Matrix<n, k, R> {
        return submatrix(inRange: (0 ..< rows, c))
    }
    
    public func submatrix<k: _Int, l: _Int>(inRange ranges: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> Matrix<k, l, R> {
        let (r, c) = ranges
        return Matrix<k, l, R>(rows: r.upperBound - r.lowerBound, cols: c.upperBound - c.lowerBound, type: type) {
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
        let d = (gridIndex(i1, 0) - gridIndex(i0, 0))
        
        p0 += gridIndex(i0, 0)
        
        for _ in 0 ..< cols {
            let a = p0.pointee
            
            let p1 = p0 + d
            let b = p1.pointee
            
            p1.pointee = b + r * a
            p0 += 1
        }
    }
    
    public mutating func addCol(at j0: Int, to j1: Int, multipliedBy r: R = 1) {
        var p0 = UnsafeMutablePointer(&grid)
        let d = (gridIndex(0, j1) - gridIndex(0, j0))

        p0 += gridIndex(0, j0)
        
        for _ in 0 ..< rows {
            let a = p0.pointee
            
            let p1 = p0 + d
            let b = p1.pointee
            
            p1.pointee = b + r * a
            p0 += cols
        }
    }
    
    public mutating func swapRows(_ i0: Int, _ i1: Int) {
        var p0 = UnsafeMutablePointer(&grid)
        let d = (gridIndex(i1, 0) - gridIndex(i0, 0))
        
        p0 += gridIndex(i0, 0)
        
        for _ in 0 ..< cols {
            let a = p0.pointee
            let p1 = p0 + d
            
            p0.pointee = p1.pointee
            p1.pointee = a
            
            p0 += 1
        }
    }
    
    public mutating func swapCols(_ j0: Int, _ j1: Int) {
        var p0 = UnsafeMutablePointer(&grid)
        let d = (gridIndex(0, j1) - gridIndex(0, j0))
        
        p0 += gridIndex(0, j0)
        
        for _ in 0 ..< rows {
            let a = p0.pointee
            let p1 = p0 + d
            
            p0.pointee = p1.pointee
            p1.pointee = a
            
            p0 += cols
        }
    }
    
    public var eliminatable: Bool {
        return true // FIXME
    }
    
    public func eliminate(debug: Bool = false) -> MatrixEliminator<n, m, R> {
        guard let e = R.matrixEliminatiorType()?.init(self, debug) else {
            fatalError("MatrixElimination not available for ring: \(R.symbol)")
        }
        e.run()
        return e
    }
    
    public var smithNormalForm: MatrixEliminator<n, m, R> {
        if let e = smithNormalFormCache.value {
            return e
        }
        
        let e = self.eliminate()
        smithNormalFormCache.value = e
        return e
    }
    
    public var rank: Int {
        return smithNormalForm.diagonal.filter{ $0 != 0 }.count
    }
    
    public var kernelMatrix: Matrix<m, Dynamic, R> {
        return smithNormalForm.right.submatrix(colsInRange: rank ..< cols)
    }
    
    public var kernelVectors: [ColVector<m, R>] {
        return kernelMatrix.toColVectors()
    }
    
    public var imageMatrix: Matrix<n, Dynamic, R> {
        let d = smithNormalForm.diagonal
        var a: Matrix<n, Dynamic, R> = smithNormalForm.leftInverse.submatrix(colsInRange: 0 ..< rank)
        
        (0 ..< Swift.min(d.count, a.cols)).forEach {
            a.multiplyCol(at: $0, by: d[$0])
        }
        
        return a
    }
    
    public var imageVectors: [ColVector<n, R>] {
        return imageMatrix.toColVectors()
    }
    
    public var asDynamic: DynamicMatrix<R> {
        if let A = self as? DynamicMatrix<R> {
            return A
        } else {
            return DynamicMatrix<R>(rows, cols, type, grid)
        }
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
    
    public var detailDescription: String {
        return "[\t" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joined(separator: ",\t")
        }).joined(separator: "\n\t") + "]"
    }
    
    public static var symbol: String {
        return "M(\((n.self == Dynamic.self ? "?" : "\(n.intValue)")), \((m.self == Dynamic.self ? "?" : "\(m.intValue)")); \(R.symbol))"
    }
    
    private static func determineSize(_ rows: Int?, _ cols: Int?) -> (rows: Int, cols: Int) {
        // true: determined, false: not determined
        switch (!(n.self is Dynamic.Type), !(m.self is Dynamic.Type), rows != nil, cols != nil) {
        case (true, true, _, _):
            assert(rows == nil || rows! == n.intValue, "rows mismatch with type-parameter")
            assert(cols == nil || cols! == m.intValue, "cols mismatch with type-parameter")
            return (n.intValue, m.intValue)
        case (false, false, true, true):
            return (rows!, cols!)
        case (true, false, _, true):
            assert(rows == nil || rows! == n.intValue, "rows mismatch with type-parameter")
            return (n.intValue, cols!)
        case (false, true, true, _):
            assert(cols == nil || cols! == m.intValue, "cols mismatch with type-parameter")
            return (rows!, m.intValue)
        default:
            fatalError("Matrix size indeterminable.")
        }
    }
}

public extension Matrix where m == _1 {
    public subscript(index: Int) -> R {
        @_transparent
        get { return self[index, 0] }
        
        @_transparent
        set { self[index, 0] = newValue }
    }
}

public extension Matrix where n == _1 {
    public subscript(index: Int) -> R {
        @_transparent
        get { return self[0, index] }
        
        @_transparent
        set { self[0, index] = newValue }
    }
}

// TODO: conform to Ring after conditional conformance is supported.
public extension Matrix where n == m {
    public var determinant: R {
        if eliminatable {
            let s = smithNormalForm
            return s.process.map{ $0.determinant.inverse! }.multiplyAll() * s.diagonal.multiplyAll()
        } else {
            print("[warn] running inefficient determinant calculation.")
            
            let n = rows
            return n.permutations.map { (s: [Int]) -> R in
                let e = Permutation<Dynamic>(elements: s).signature
                let p = (0 ..< n).map { self[$0, s[$0]] }.multiplyAll()
                return R(intValue: e) * p
                }.sumAll()
        }
    }
    
    public var isInvertible: Bool {
        if eliminatable {
            return smithNormalForm.diagonal.multiplyAll().isInvertible
        } else {
            return determinant.isInvertible
        }
    }
    
    public var inverse: Matrix<n, n, R>? {
        if eliminatable {
            let s = smithNormalForm
            if s.result == self.leftIdentity {
                return s.right * s.left
            } else {
                return nil
            }
        } else {
            fatalError("matrix-inverse not yet impled for general coeff-rings.")
        }
    }
    
    public static var identity: Matrix<n, n, R> {
        return Matrix<n, n, R> { $0 == $1 ? 1 : 0 }
    }
    
    public static func ** (a: Matrix<n, n, R>, k: Int) -> Matrix<n, n, R> {
        return k == 0 ? a.leftIdentity : a * (a ** (k - 1))
    }
}
