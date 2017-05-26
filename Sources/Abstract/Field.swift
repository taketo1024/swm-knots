import Foundation

public protocol Field: Group, EuclideanRing {
}

public func / <F: Field>(a: F, b: F) -> F {
    return a * b.inverse
}

public extension Field {
    var isUnit: Bool {
        return self != 0
    }
    
    var degree: Int {
        return self == Self.zero ? 0 : 1
    }
    
    static func eucDiv(_ a: Self, _ b: Self) -> (q: Self, r: Self) {
        return (a/b, 0)
    }
    
    static func matrixElimination<n:_Int, m:_Int>(_ A: Matrix<Self, n, m>, mode: MatrixEliminationMode) -> BaseMatrixElimination<Self, n, m> {
        return FieldMatrixElimination<Self, n, m>(A, mode: mode)
    }
}
