import Foundation

public enum MatrixEliminationMode {
    case Both
    case Rows
    case Cols
}

public class MatrixElimination<R: Ring, n: _Int, m: _Int> {
    internal let processor: MatrixEliminationProcessor<R>
    
    private lazy var result: (matrix: _MatrixImpl<R>, process: [EliminationStep<R>]) = {[unowned self] in
        let p = self.processor
        p.run()
        return (p.result, p.process)
    }()
    
    internal init(_ matrix: _MatrixImpl<R>, _ mode: MatrixEliminationMode, _ processorType: MatrixEliminationProcessor<R>.Type) {
        self.processor = processorType.init(matrix, mode)
    }
    
    public var rankNormalForm: Matrix<R, n, m> {
        return Matrix(result.matrix)
    }
    
    public var left: Matrix<R, n, n> {
        let Q = result.matrix.leftIdentity()
        
        result.process
            .filter{ $0.isRowOperation }
            .forEach { $0.apply(to: Q) }
        
        return Matrix(Q)
    }
    
    public var leftInverse: Matrix<R, n, n> {
        let Q = result.matrix.leftIdentity()
        
        result.process
            .filter{ $0.isRowOperation }
            .reversed()
            .forEach{ $0.inverse.apply(to: Q) }
        
        return Matrix(Q)
    }
    
    public var right: Matrix<R, m, m> {
        let P = result.matrix.rightIdentity()
        
        result.process
            .filter{ $0.isColOperation }
            .forEach { $0.apply(to: P) }
        
        return Matrix(P)
    }
    
    public var rightInverse: Matrix<R, m, m> {
        let P = result.matrix.rightIdentity()
        
        result.process
            .filter{ $0.isColOperation }
            .reversed()
            .forEach{ $0.inverse.apply(to: P) }
        
        return Matrix(P)
    }
    
    public var diagonal: [R] {
        let A = result.matrix
        let r = min(A.rows, A.cols)
        return (0 ..< r).map{ A[$0, $0] }
    }
    
    public var determinant: R {
        // FIXME this is wrong! consider sign.
        return diagonal.reduce(R.identity) { $0 * $1 }
    }
    
    public var rank: Int {
        let A = result.matrix
        let r = min(A.rows, A.cols)
        return (0 ..< r).filter{ A[$0, $0] != R.zero }.count
    }
    
    public var nullity: Int {
        return result.matrix.cols - rank
    }
    
    public var kernelPart: Matrix<R, m, Dynamic> {
        return right.submatrix(colsInRange: rank ..< result.matrix.cols)
    }
    
    public var kernelVectors: [ColVector<R, m>] {
        return kernelPart.toColVectors()
    }
    
    public var imagePart: Matrix<R, n, Dynamic> {
        let d = diagonal
        var a: Matrix<R, n, Dynamic> = leftInverse.submatrix(colsInRange: 0 ..< self.rank)
        (0 ..< min(d.count, a.cols)).forEach {
            a.multiplyCol(at: $0, by: d[$0])
        }
        return a
    }
    
    public var imageVectors: [ColVector<R, n>] {
        return imagePart.toColVectors()
    }
}
