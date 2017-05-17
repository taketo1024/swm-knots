import Foundation

public enum MatrixEliminationMode {
    case Both
    case Rows
    case Cols
}

// an abstract class
public class BaseMatrixElimination<R: Ring, n: _Int, m: _Int> {
    public let target: Matrix<R, n, m>
    public let mode: MatrixEliminationMode
    fileprivate let rows: Int
    fileprivate let cols: Int
    
    public init(_ matrix: Matrix<R, n, m>, mode: MatrixEliminationMode = .Both) {
        self.target = matrix
        self.mode = mode
        self.rows = matrix.rows
        self.cols = matrix.cols
    }
    
    // override point
    fileprivate func processor() -> BaseEliminationProcessor<R, n, m> {
        fatalError("MatrixElimination is not impled for Ring \(R.self).")
    }
    
    fileprivate var resultStorage: (matrix: Matrix<R, n, m>, process: [EliminationStep<R>])?
    fileprivate var result: (matrix: Matrix<R, n, m>, process: [EliminationStep<R>]) {
        switch resultStorage {
        case let r?:
            return r
        default:
            let e = processor()
            e.run()
            
            let result = (e.result, e.process)
            resultStorage = result
            return result
        }
    }
    
    public var rankNormalForm: Matrix<R, n, m> {
        return result.matrix
    }
    
    private var eliminationProcess: [EliminationStep<R>] {
        return result.process
    }
    
    public var left: Matrix<R, n, n> {
        var Q = target.leftIdentity
        
        eliminationProcess
            .filter{ $0.isRowOperation }
            .forEach { Q.apply($0) }
        
        return Q
    }
    
    public var leftInverse: Matrix<R, n, n> {
        var Q = target.leftIdentity
        
        eliminationProcess
            .filter{ $0.isRowOperation }
            .reversed()
            .map { invert($0) }
            .forEach{ Q.apply($0) }
        
        return Q
    }
    
    public var right: Matrix<R, m, m> {
        var P = target.rightIdentity
        
        eliminationProcess
            .filter{ $0.isColOperation }
            .forEach { P.apply($0) }
        
        return P
    }
    
    public var rightInverse: Matrix<R, m, m> {
        var P = target.rightIdentity
        
        eliminationProcess
            .filter{ $0.isColOperation }
            .reversed()
            .map { invert($0) }
            .forEach{ P.apply($0) }
        
        return P
    }
    
    public var diagonal: [R] {
        let B = rankNormalForm
        let r = min(self.rows, self.cols)
        return (0 ..< r).map{ B[$0, $0] }
    }
    
    public var rank: Int {
        let B = rankNormalForm
        let r = min(self.rows, self.cols)
        return (0 ..< r).filter{ B[$0, $0] != R.zero }.count
    }
    
    public var nullity: Int {
        return cols - rank
    }
    
    public var kernelPart: Matrix<R, m, _TypeLooseSize> {
        return right.submatrix(colsInRange: rank ..< cols)
    }
    
    public var kernelVectors: [ColVector<R, m>] {
        return kernelPart.toColVectors()
    }
    
    public var imagePart: Matrix<R, n, _TypeLooseSize> {
        let d = diagonal
        var a: Matrix<R, n, _TypeLooseSize> = leftInverse.submatrix(colsInRange: 0 ..< self.rank)
        a.replaceElements() { (i, j) in d[j] * a[i, j] }
        return a
    }
    
    public var imageVectors: [ColVector<R, n>] {
        return imagePart.toColVectors()
    }
    
    fileprivate func invert(_ s: EliminationStep<R>) -> EliminationStep<R> {
        switch s {
        case let .AddRow(i, j, r):
            return .AddRow(at: i, to: j, mul: -r)
        case let .AddCol(i, j, r):
            return .AddCol(at: i, to: j, mul: -r)
        case .MulRow(at: _, by: -1), .MulCol(at: _, by: -1), .SwapRows(_, _), .SwapCols(_, _):
            return s
        default:
            fatalError("\(s) in not invertible.")
        }
    }
}

public class EuclideanMatrixElimination<R: EuclideanRing, n: _Int, m: _Int>: BaseMatrixElimination<R, n, m> {
    fileprivate override func processor() -> BaseEliminationProcessor<R, n, m> {
        return EuclideanEliminationProcessor(target, mode)
    }
}

public class FieldMatrixElimination<R: Field, n: _Int, m: _Int>: BaseMatrixElimination<R, n, m> {
    fileprivate override func processor() -> BaseEliminationProcessor<R, n, m> {
        return FieldEliminationProcessor(target, mode)
    }

    fileprivate override func invert(_ s: EliminationStep<R>) -> EliminationStep<R> {
        switch s {
        case let .MulRow(at: i, by: r):
            return .MulRow(at: i, by: r.inverse)
        case let .MulCol(at: i, by: r):
            return .MulCol(at: i, by: r.inverse)
        default:
            return super.invert(s)
        }
    }
}

// EliminationStep

fileprivate enum EliminationStep<R: Ring> {
    case AddRow(at: Int, to: Int, mul: R)
    case MulRow(at: Int, by: R)
    case SwapRows(Int, Int)
    case AddCol(at: Int, to: Int, mul: R)
    case MulCol(at: Int, by: R)
    case SwapCols(Int, Int)
    
    var isRowOperation: Bool {
        switch self {
        case .AddRow, .MulRow, .SwapRows: return true
        default: return false
        }
    }
    
    var isColOperation: Bool {
        switch self {
        case .AddCol, .MulCol, .SwapCols: return true
        default: return false
        }
    }
}

fileprivate extension Matrix {
    mutating func apply(_ s: EliminationStep<R>) {
        switch s {
        case let .AddRow(i, j, r):
            addRow(at: i, to: j, multipliedBy: r)
        case let .MulRow(i, r):
            multiplyRow(at: i, by: r)
        case let .SwapRows(i, j):
            swapRows(i, j)
        case let .AddCol(i, j, r):
            addCol(at: i, to: j, multipliedBy: r)
        case let .MulCol(i, r):
            multiplyCol(at: i, by: r)
        case let .SwapCols(i, j):
            swapCols(i, j)
        }
    }
}

// EliminationProcessor

// base abstract class
fileprivate class BaseEliminationProcessor<R: Ring, n: _Int, m: _Int> {
    let mode: MatrixEliminationMode
    let rows: Int
    let cols: Int
    
    var result: Matrix<R, n, m>
    var process: [EliminationStep<R>]
    private(set) var itr = 0
    
    init(_ target: Matrix<R, n, m>, _ mode: MatrixEliminationMode = .Both) {
        self.mode = mode
        self.rows = target.rows
        self.cols = target.cols
        self.result = target
        self.process = []
    }
    
    func run() {
        let maxItr: Int = {
            switch mode {
            case .Both: return min(rows, cols)
            case .Rows: return rows
            case .Cols: return cols
            }
        }()
        
        while itr < maxItr {
            if iteration() {
                itr += 1
            } else {
                break
            }
        }
        
        postProcess()
    }
    
    // override point
    func iteration() -> Bool {
        fatalError()
    }
    
    func apply(_ s: EliminationStep<R>) {
        result.apply(s)
        process.append(s)
    }
    
    func postProcess() {
    }
    
    // TODO better use lazy sequence.
    func indexIterator() -> IndexingIterator<[(Int, Int)]> {
        switch mode {
        case .Both:
            return (itr ..< rows).flatMap{ i in
                     (itr ..< cols).map{ j in (i, j) }
                   }.makeIterator()
        case .Rows:
            return (itr ..< rows).flatMap{ i in
                     (0 ..< cols).map{ j in (i, j) }
                   }.makeIterator()
        case .Cols:
            return (itr ..< cols).flatMap{ j in
                     (0 ..< rows).map{ i in (i, j) }
                   }.makeIterator()
        }
    }
}

fileprivate class EuclideanEliminationProcessor<R: EuclideanRing, n: _Int, m: _Int>: BaseEliminationProcessor<R, n, m> {
    
    override func iteration() -> Bool {
        let doRows = (mode != .Cols)
        let doCols = (mode != .Rows)

        guard var (i0, j0) = next() else {
            return false
        }
        
        elimination: while true {
            if doRows && !eliminateRow(&i0, j0) {
                continue elimination
            }
            if doCols && !eliminateCol(i0, &j0) {
                continue elimination
            }
            
            if doRows && doCols {
                let a = result[i0, j0]
                for i in itr ..< rows {
                    for j in itr ..< cols {
                        if i == i0 || j == j0 || result[i, j] == 0 {
                            continue
                        }
                        
                        let b = result[i, j]
                        if b % a != 0 {
                            self.apply(.AddRow(at: i, to: i0, mul: 1))
                            continue elimination
                        }
                    }
                }
            }
            break elimination
        }
        
        // TODO maybe implement NumberType or Comparable
        if R.self == IntegerNumber.self && (result[i0, j0] as! IntegerNumber) < 0 {
            if doRows {
                self.apply(.MulRow(at: i0, by: -1))
            } else {
                self.apply(.MulCol(at: j0, by: -1))
            }
        }
        
        if doRows && i0 > itr {
            self.apply(.SwapRows(itr, i0))
        }
        
        if doCols && j0 > itr {
            self.apply(.SwapCols(itr, j0))
        }
        
        return true
    }
    
    override func postProcess() {
        switch mode {
        case .Rows:
            var step = 0
            align: while step < rows {
                for j in 0 ..< cols {
                    let arr = (step ..< rows).filter{ result[$0, j] != 0}
                    if arr.count == 1, let i = arr.first {
                        apply(.SwapRows(i, step))
                        step += 1
                        continue align
                    }
                }
                step += 1
            }
        case .Cols:
            var step = 0
            align: while step < cols {
                for i in 0 ..< rows {
                    let arr = (step ..< cols).filter{ result[i, $0] != 0}
                    if arr.count == 1, let j = arr.first {
                        apply(.SwapCols(j, step))
                        step += 1
                        continue align
                    }
                }
                step += 1
            }
        default: ()
        }
    }
    
    private func eliminateRow(_ i0: inout Int, _ j0: Int) -> Bool {
        let a = result[i0, j0]
        
        for i in itr ..< rows {
            if i == i0 || result[i, j0] == 0 {
                continue
            }
            
            let b = result[i, j0]
            let (q, r) = b /% a
            
            self.apply(.AddRow(at: i0, to: i, mul: -q))
            
            if r != 0 {
                i0 = i
                return false
            }
        }
        
        // at this point, it is guaranteed that result[i, j0] == 0 for (i >= itr, i != i0)
        
        if mode == .Rows {
            for i in 0 ..< itr {
                if i == i0 || result[i, j0] == 0 {
                    continue
                }
                
                let b = result[i, j0]
                let (q, _) = b /% a
                
                self.apply(.AddRow(at: i0, to: i, mul: -q))
            }
        }
        
        return true
    }
    
    private func eliminateCol(_ i0: Int, _ j0: inout Int) -> Bool {
        let a = result[i0, j0]
        
        for j in itr ..< cols {
            if j == j0 || result[i0, j] == 0 {
                continue
            }
            
            let b = result[i0, j]
            let (q, r) = b /% a
            
            self.apply(.AddCol(at: j0, to: j, mul: -q))
            
            if r != 0 {
                j0 = j
                return false
            }
        }
        
        // at this point, it is guaranteed that result[i0, j] == 0 for (j >= itr, j != j0)
        
        if mode == .Cols {
            for j in 0 ..< itr {
                if j == j0 || result[i0, j] == 0 {
                    continue
                }
                
                let b = result[i0, j]
                let (q, _) = b /% a
                
                self.apply(.AddCol(at: j0, to: j, mul: -q))
            }
        }
        
        return true
    }
    
    private func next() -> (Int, Int)? {
        let res = indexIterator().reduce(nil) { (res: (R, Int, Int)?, next: (Int, Int)) -> (R, Int, Int)? in
            let (i, j) = next
            let a = result[i, j]
            
            if a != 0 && (res == nil || a.degree < res!.0.degree) {
                return (a, i, j)
            } else {
                return res
            }
        }
        
        return res.flatMap{ res in (res.1, res.2) }
    }
}

fileprivate class FieldEliminationProcessor<R: Field, n: _Int, m: _Int>: BaseEliminationProcessor<R, n, m> {
    
    override func iteration() -> Bool {
        let doRows = (mode != .Cols)
        let doCols = (mode != .Rows)
        
        guard var (i0, j0) = next() else {
            return false
        }
        
        if doRows && i0 > itr {
            self.apply(.SwapRows(itr, i0))
            i0 = itr
        }
        
        if doCols && j0 > itr {
            self.apply(.SwapCols(itr, j0))
            j0 = itr
        }
        
        if doRows {
            eliminateRow(i0, j0)
        }
        
        if doCols {
            eliminateCol(i0, j0)
        }
    
        return true
    }
    
    private func eliminateRow(_ i0: Int, _ j0: Int) {
        let a = result[i0, j0]
        if a != R.identity {
            apply(.MulRow(at: i0, by: a.inverse))
        }
        
        for i in itr ..< rows {
            if i == i0 || result[i, j0] == 0 {
                continue
            }
            
            apply(.AddRow(at: i0, to: i, mul: -result[i, j0]))
        }
    }
    
    private func eliminateCol(_ i0: Int, _ j0: Int) {
        let a = result[i0, j0]
        if a != R.identity {
            apply(.MulCol(at: i0, by: a.inverse))
        }
        
        for j in itr ..< cols {
            if j == j0 || result[i0, j] == 0 {
                continue
            }
            
            apply(.AddCol(at: j0, to: j, mul: -result[i0, j]))
        }
    }
    
    private func next() -> (row: Int, col: Int)? {
        for (i, j) in indexIterator() {
            let a = result[i, j]
            if a != 0 {
                return (i, j)
            }
        }
        return nil
    }
}

