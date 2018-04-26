import Foundation

public struct Matrix<n: _Int, m: _Int, R: Ring>: Module, Sequence {
    public typealias CoeffRing = R
    
    internal var impl: MatrixImpl<R>
    
    internal init(_ impl: MatrixImpl<R>) {
        self.impl = impl
    }
    
    // 1. Initialize by Grid.
    public init(grid: [R]) {
        assert(!n.isDynamic && !m.isDynamic)
        let (rows, cols) = (n.intValue, m.intValue)
        self.init(MatrixImpl(rows: rows, cols: cols, grid: grid))
    }
    
    public init(_ grid: R...) {
        self.init(grid: grid)
    }
    
    // 2. Initialize by Generator.
    public init(generator g: (Int, Int) -> R) {
        assert(!n.isDynamic && !m.isDynamic)
        let (rows, cols) = (n.intValue, m.intValue)
        self.init(MatrixImpl(rows: rows, cols: cols, generator: g))
    }
    
    // 3. Initialize by Components.
    public init(components: [MatrixComponent<R>]) {
        assert(!n.isDynamic && !m.isDynamic)
        let (rows, cols) = (n.intValue, m.intValue)
        self.init(MatrixImpl(rows: rows, cols: cols, components: components))
    }
    
    // Convenience Initializer 1.
    public init(fill a: R) {
        self.init() { (_, _) in a }
    }
    
    // Convenience Initializer 2.
    public init(diagonal d: [R]) {
        self.init() { (i, j) in (i == j && i < d.count) ? d[i] : .zero }
    }
    
    // Convenience Initializer 3.
    public init(scalar a: R) {
        self.init() { (i, j) in (i == j) ? a : .zero }
    }
    
    // Block Matrix [A, B; C, D]
    public init<n1, n2, m1, m2>(_ A: Matrix<n1, m1, R>, _ B: Matrix<n1, m2, R>, _ C: Matrix<n2, m1, R>, _ D: Matrix<n2, m2, R>) {
        let (n1, n2, m1, m2) = (n1.intValue, n2.intValue, m1.intValue, m2.intValue)
        assert(n1 + n2 == n.intValue)
        assert(m1 + m2 == m.intValue)
        self.init() { (i, j) in
            switch (i, j) {
            case (i, j) where i <  n1 && j <  m1: return A[i, j]
            case (i, j) where i >= n1 && j <  m1: return B[i - n1, j]
            case (i, j) where i <  n1 && j >= m1: return C[i, j - m1]
            case (i, j) where i >= n1 && j >= m1: return D[i - n1, j - m1]
            default: return .zero
            }
        }
    }
    
    private mutating func willMutate() {
        if !isKnownUniquelyReferenced(&impl) {
            impl = impl.copy()
        }
    }
    
    public var rows: Int { return impl.rows }
    public var cols: Int { return impl.cols }
    
    public subscript(i: Int, j: Int) -> R {
        get {
            return impl[i, j]
        } set {
            willMutate()
            fatalError("TODO")
        }
    }
    
    public static var zero: Matrix<n, m, R> {
        return Matrix<n, m, R> { _,_ in .zero }
    }
    
    public static func unit(_ i0: Int, _ j0: Int) -> Matrix<n, m, R> {
        return Matrix { (i, j) in (i, j) == (i0, j0) ? .identity : .zero }
    }
    
    public static func ==(a: Matrix<n, m, R>, b: Matrix<n, m, R>) -> Bool {
        return a.impl == b.impl
    }
    
    public static func +(a: Matrix<n, m, R>, b: Matrix<n, m, R>) -> Matrix<n, m, R> {
        return Matrix(a.impl + b.impl)
    }
    
    public prefix static func -(a: Matrix<n, m, R>) -> Matrix<n, m, R> {
        return Matrix(-a.impl)
    }
    
    public static func *(r: R, a: Matrix<n, m, R>) -> Matrix<n, m, R> {
        return Matrix(r * a.impl)
    }
    
    public static func *(a: Matrix<n, m, R>, r: R) -> Matrix<n, m, R> {
        return Matrix(a.impl * r)
    }
    
    public static func * <p>(a: Matrix<n, m, R>, b: Matrix<m, p, R>) -> Matrix<n, p, R> {
        return Matrix<n, p, R>(a.impl * b.impl)
    }
    
    public var transposed: Matrix<m, n, R> {
        return Matrix<m, n, R>(impl.transposed)
    }
    
    public func rowVector(_ i: Int) -> RowVector<m, R> {
        return submatrix(rowRange: i ..< i + 1)
    }
    
    public func colVector(_ j: Int) -> ColVector<n, R> {
        return submatrix(colRange: j ..< j + 1)
    }
    
    public func submatrix<k: _Int>(rowRange: CountableRange<Int>) -> Matrix<k, m, R> {
        return submatrix(rowRange, 0 ..< cols)
    }
    
    public func submatrix<k: _Int>(colRange: CountableRange<Int>) -> Matrix<n, k, R> {
        return submatrix(0 ..< rows, colRange)
    }
    
    public func submatrix<k: _Int, l: _Int>(_ rowRange: CountableRange<Int>, _ colRange: CountableRange<Int>) -> Matrix<k, l, R> {
        return Matrix<k, l, R>(impl.submatrix(rowRange, colRange))
    }
    
    public var grid: [R] {
        return impl.grid
    }
    
    public var components: [MatrixComponent<R>] {
        return impl.components
    }
    
    // TODO directly iterate impl
    public func makeIterator() -> IndexingIterator<[(Int, Int, R)]> {
        return components.map{ c in (c.row, c.col, c.value) }.makeIterator()
    }
    
    public var hashValue: Int {
        return impl.hashValue
    }
    
    public var description: String {
        return "[" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joined(separator: ", ")
        }).joined(separator: "; ") + "]"
    }
    
    public var detailDescription: String {
        if (rows, cols) == (0, 0) {
            return "[]"
        } else if rows == 0 {
            return "[" + String(repeating: "\t,", count: cols - 1) + "\t]"
        } else if cols == 0 {
            return "[" + String(repeating: "\t;", count: rows - 1) + "\t]"
        } else {
            return "[\t" + (0 ..< rows).map({ i in
                return (0 ..< cols).map({ j in
                    return "\(self[i, j])"
                }).joined(separator: ",\t")
            }).joined(separator: "\n\t") + "]"
        }
    }
    
    public static var symbol: String {
        return "M(\(n.isDynamic ? "D" : String(n.intValue)), \(m.isDynamic ? "D" : String(m.intValue)); \(R.symbol))"
    }
}

extension Matrix: VectorSpace, FiniteDimVectorSpace where R: Field {
    public static var dim: Int {
        assert(!n.isDynamic && !m.isDynamic)
        return n.intValue * m.intValue
    }
    
    public static var standardBasis: [Matrix<n, m, R>] {
        assert(!n.isDynamic && !m.isDynamic)
        return (0 ..< n.intValue).flatMap { i -> [Matrix<n, m, R>] in
            (0 ..< m.intValue).map { j -> Matrix<n, m, R> in
                Matrix.unit(i, j)
            }
        }
    }
    
    public var standardCoordinates: [R] {
        return grid
    }
}

public extension Matrix where R: EuclideanRing {
    public func eliminate(form: MatrixForm = .Diagonal) -> MatrixEliminationResultWrapper<n, m, R> {
        let result = impl.copy().eliminate(form: form)
        return MatrixEliminationResultWrapper(self, result)
    }
}

extension Matrix: NormedSpace where R: NormedSpace {
    public var norm: 𝐑 {
        return √( sum { (_, _, a) in a.norm.pow(2) } )
    }
    
    public var maxNorm: 𝐑 {
        return self.map { $0.2.norm }.max() ?? 𝐑.zero
    }
}

public extension Matrix where R == 𝐑 {
    public var asComplex: Matrix<n, m, 𝐂> {
        return Matrix<n, m, 𝐂>(impl.mapValues{ $0.asSuper })
    }
}

public extension Matrix where R == 𝐂 {
    public var realPart: Matrix<n, m, 𝐑> {
        return Matrix<n, m, 𝐑>(impl.mapValues{ $0.realPart })
    }
    
    public var imaginaryPart: Matrix<n, m, 𝐑> {
        return Matrix<n, m, 𝐑>(impl.mapValues{ $0.imaginaryPart })
    }
    
    public var adjoint: Matrix<m, n, R> {
        return Matrix<m, n, R>(impl.transposed.mapValues{ $0.conjugate })
    }
}

public typealias DynamicMatrix<R: Ring> = Matrix<Dynamic, Dynamic, R>

public extension Matrix where n == Dynamic, m == Dynamic {
    internal init(rows: Int, cols: Int, grid: [R]) {
        self.init(MatrixImpl(rows: rows, cols: cols, grid: grid))
    }
    
    internal init(rows: Int, cols: Int, generator g: (Int, Int) -> R) {
        self.init(MatrixImpl(rows: rows, cols: cols, generator: g))
    }
    
    internal init(rows: Int, cols: Int, components: [MatrixComponent<R>]) {
        self.init(MatrixImpl(rows: rows, cols: cols, components: components))
    }
}
