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

public struct Matrix<R: Ring, n: _Int, m: _Int>: Module, Sequence {
    public typealias CoeffRing = R
    public typealias Iterator = MatrixIterator<R, n, m>
    
    public let rows: Int
    public let cols: Int
    public let type: MatrixType
    
    private var grid: [R] {
        willSet {
            clearCache()
        }
    }
    
    internal var smithNormalFormCache: Cache<MatrixEliminator<R, n, m>> = Cache()
    internal func clearCache() {
        smithNormalFormCache.value = nil
    }

    // Root Initializer.
    private init(_ rows: Int, _ cols: Int, _ type: MatrixType, _ grid: [R]) {
        self.rows = rows
        self.cols = cols
        self.type = type
        self.grid = grid
    }
    
    // 1. Initialize by Grid.
    public init(rows r: Int? = nil, cols c: Int? = nil, type: MatrixType = .Default, grid: [R]) {
        let (rows, cols) = Matrix.determineSize(r, c, grid)
        self.init(rows, cols, type, grid)
    }
    
    // 2. Initialize by Generator.
    public init(rows r: Int? = nil, cols c: Int? = nil, type: MatrixType = .Default, generator g: (Int, Int) -> R) {
        let (rows, cols) = Matrix.determineSize(r, c, nil)
        let grid = (0 ..< rows * cols).map { (index: Int) -> R in
            let (i, j) = index /% cols
            return g(i, j)
        }
        self.init(rows, cols, type, grid)
    }
    
    // 3. Initialize by Components (good for Sparce Matrix).
    public init(rows r: Int? = nil, cols c: Int? = nil, type: MatrixType = .Default, components: [MatrixComponent<R>]) {
        let (rows, cols) = Matrix.determineSize(r, c, nil)
        var grid = Array(repeating: R.zero, count: rows * cols)
        for (i, j, a) in components {
            grid[(i * cols) + j] = a
        }
        self.init(rows, cols, type, grid)
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
    
    internal func gridIndex(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(i: Int, j: Int) -> R {
        get {
            return grid[gridIndex(i, j)]
        } set {
            grid[gridIndex(i, j)] = newValue
        }
    }
    
    public func makeIterator() -> MatrixIterator<R, n, m> {
        return MatrixIterator(self)
    }
    
    public static var zero: Matrix<R, n, m> {
        return Matrix<R, n, m> { _,_ in 0 }
    }
    
    public static func ==(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Bool {
        assert((a.rows, a.cols) == (b.rows, b.cols), "Mismatching matrix size.")
        return a.grid == b.grid
    }
    
    public static func +(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Matrix<R, n, m> {
        assert((a.rows, a.cols) == (b.rows, b.cols), "Mismatching matrix size.")
        return Matrix(rows: a.rows, cols: a.cols, type: (a.type == b.type) ? a.type : .Default) { (i, j) -> R in
            return a[i, j] + b[i, j]
        }
    }
    
    public prefix static func -(a: Matrix<R, n, m>) -> Matrix<R, n, m> {
        return Matrix(rows: a.rows, cols: a.cols, type: a.type) { (i, j) -> R in
            return -a[i, j]
        }
    }
    
    public static func *(r: R, a: Matrix<R, n, m>) -> Matrix<R, n, m> {
        return Matrix(rows: a.rows, cols: a.cols, type: a.type) { (i, j) -> R in
            return r * a[i, j]
        }
    }
    
    public static func *(a: Matrix<R, n, m>, r: R) -> Matrix<R, n, m> {
        return Matrix(rows: a.rows, cols: a.cols, type: a.type) { (i, j) -> R in
            return a[i, j] * r
        }
    }
    
    public static func * <p>(a: Matrix<R, n, m>, b: Matrix<R, m, p>) -> Matrix<R, n, p> {
        assert(a.cols == b.rows, "Mismatching matrix size.")
        return Matrix<R, n, p>(rows: a.rows, cols: b.cols, type: (a.type == b.type) ? a.type : .Default) { (i, k) -> R in
            return (0 ..< a.cols)
                .map({j in a[i, j] * b[j, k]})
                .reduce(0) {$0 + $1}
        }
    }
    
    public var transposed: Matrix<R, m, n> {
        return Matrix<R, m, n>(rows: cols, cols: rows, type: type) { (i, j) -> R in
            return self[j, i]
        }
    }
    
    public var leftIdentity: Matrix<R, n, n> {
        return Matrix<R, n, n>(rows: rows, cols: rows, type: type) { $0 == $1 ? 1 : 0 }
    }
    
    public var rightIdentity: Matrix<R, m, m> {
        return Matrix<R, m, m>(rows: cols, cols: cols, type: type) { $0 == $1 ? 1 : 0 }
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
        return submatrix(inRange: (i ..< i + 1, 0 ..< cols))
    }
    
    public func colVector(_ j: Int) -> ColVector<R, n> {
        return submatrix(inRange: (0 ..< rows, j ..< j + 1))
    }
    
    public func toRowVectors() -> [RowVector<R, m>] {
        return (0 ..< rows).map{ rowVector($0) }
    }
    
    public func toColVectors() -> [ColVector<R, n>] {
        return (0 ..< cols).map{ colVector($0) }
    }
    
    public func submatrix<k: _Int>(rowsInRange r: CountableRange<Int>) -> Matrix<R, k, m> {
        return submatrix(inRange: (r, 0 ..< cols))
    }
    
    public func submatrix<k: _Int>(colsInRange c: CountableRange<Int>) -> Matrix<R, n, k> {
        return submatrix(inRange: (0 ..< rows, c))
    }
    
    public func submatrix<k: _Int, l: _Int>(inRange ranges: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> Matrix<R, k, l> {
        let (r, c) = ranges
        return Matrix<R, k, l>(rows: r.upperBound - r.lowerBound, cols: c.upperBound - c.lowerBound, type: type) {
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
    
    public func eliminate(mode: MatrixEliminationMode, debug: Bool = false) -> MatrixEliminator<R, n, m> {
        guard let e = R.matrixEliminatiorType()?.init(self, mode, debug) else {
            fatalError("MatrixElimination not available for ring: \(R.symbol)")
        }
        return e
    }
    
    public var smithNormalForm: MatrixEliminator<R, n, m> {
        if let s = smithNormalFormCache.value {
            return s
        }
        
        let s = self.eliminate(mode: .Both)
        smithNormalFormCache.value = s
        
        return s
    }
    
    public var rank: Int {
        return smithNormalForm.diagonal.filter{ $0 != 0 }.count
    }
    
    public var kernelMatrix: Matrix<R, m, Dynamic> {
        return smithNormalForm.right.submatrix(colsInRange: rank ..< cols)
    }
    
    public var kernelVectors: [ColVector<R, m>] {
        return kernelMatrix.toColVectors()
    }
    
    public var imageMatrix: Matrix<R, n, Dynamic> {
        let d = smithNormalForm.diagonal
        var a: Matrix<R, n, Dynamic> = smithNormalForm.leftInverse.submatrix(colsInRange: 0 ..< rank)
        
        (0 ..< Swift.min(d.count, a.cols)).forEach {
            a.multiplyCol(at: $0, by: d[$0])
        }
        
        return a
    }
    
    public var imageVectors: [ColVector<R, n>] {
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
        if eliminatable {
            // FIXME this is wrong! (ignores sign)
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
    
    public var inverse: Matrix<R, n, n>? {
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
    
    public static var identity: Matrix<R, n, n> {
        return Matrix<R, n, n> { $0 == $1 ? 1 : 0 }
    }
    
    public static func ** (a: Matrix<R, n, n>, k: Int) -> Matrix<R, n, n> {
        return k == 0 ? a.leftIdentity : a * (a ** (k - 1))
    }
}
