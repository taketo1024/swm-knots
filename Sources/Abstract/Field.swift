import Foundation

public protocol Field: Group, EuclideanRing {
}

public extension Field {
    public var isUnit: Bool {
        return self != 0
    }
    
    public var unitInverse: Self? {
        return isUnit ? inverse : nil
    }
    
    public var degree: Int {
        return self == Self.zero ? 0 : 1
    }
    
    public static func / (a: Self, b: Self) -> Self {
        return a * b.inverse
    }
    
    public static func ** (a: Self, b: Int) -> Self {
        switch b {
        case let n where n > 0:
            return a * (a ** (n - 1))
        case let n where n < 0:
            return a.inverse * (a ** (n + 1))
        default:
            return Self.identity
        }
    }
    
    public static func eucDiv(_ a: Self, _ b: Self) -> (q: Self, r: Self) {
        return (a/b, 0)
    }
    
    public static func matrixElimination<n:_Int, m:_Int>(_ A: Matrix<Self, n, m>, mode: MatrixEliminationMode) -> BaseMatrixElimination<Self, n, m> {
        return FieldMatrixElimination<Self, n, m>(A, mode: mode)
    }
}
