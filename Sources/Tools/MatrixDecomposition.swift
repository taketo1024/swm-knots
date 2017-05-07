import Foundation

public enum EliminationMode {
    case Both
    case RowsOnly
    case ColsOnly
}

// Boxed class for lazy computation.
// B = Q A P (A: matrix, B: result, Q: left, P: right)
public class MatrixElimination<R: EuclideanRing, n: _Int, m: _Int> {
    public let target: Matrix<R, n, m>
    private let rows: Int
    private let cols: Int
    private let mode: EliminationMode
    
    public init(_ matrix: Matrix<R, n, m>, mode: EliminationMode = .Both) {
        self.target = matrix
        self.rows = matrix.rows
        self.cols = matrix.cols
        self.mode = mode
    }
    
    private lazy var process: EliminationProcess<R, n, m> = EliminationProcess(self.target, self.mode)
    
    public lazy var result: Matrix<R, n, m> = self.process.result
    
    public lazy var left: Matrix<R, n, n> = {[unowned self] in
        var Q = self.target.leftIdentity
        for s in self.process.process {
            switch s {
            case .AddRow(_, _, _), .InvRow(_), .SwapRows(_, _):
                s.applyTo(&Q)
            default: ()
            }
        }
        return Q
    }()
    
    public lazy var leftInverse: Matrix<R, n, n> = {[unowned self] in
        var Q = self.target.leftIdentity
        for s in self.process.process.reversed() {
            switch s {
            case .AddRow(_, _, _), .InvRow(_), .SwapRows(_, _):
                s.applyInverseTo(&Q)
            default: ()
            }
        }
        return Q
    }()
    
    public lazy var right: Matrix<R, m, m> = {[unowned self] in
        var P = self.target.rightIdentity
        for s in self.process.process {
            switch s {
            case .AddCol(_, _, _), .InvCol(_), .SwapCols(_, _):
                s.applyTo(&P)
            default: ()
            }
        }
        return P
    }()
    
    public lazy var rightInverse: Matrix<R, m, m> = {[unowned self] in
        var P = self.target.rightIdentity
        for s in self.process.process.reversed() {
            switch s {
            case .AddCol(_, _, _), .InvCol(_), .SwapCols(_, _):
                s.applyInverseTo(&P)
            default: ()
            }
        }
        return P
    }()
    
    public lazy var diagonal: [R] = {[unowned self] in
        let B = self.result
        return (0 ..< min(self.rows, self.cols)).map{ B[$0, $0] }
    }()
    
    public lazy var rank: Int = {[unowned self] in
        return self.diagonal.filter({$0 != 0}).count
    }()
    
    public lazy var kernelVectors: [ColVector<R, m>] = { [unowned self] in
        let P = self.right
        let k = self.cols - self.rank
        
        return (self.cols - k ..< self.cols).map { (i) -> ColVector<R, m> in
            return P * ColVector<R, m>.unit(size:self.cols, i)
        }
    }()
    
    public lazy var imageVectors: [ColVector<R, n>] = { [unowned self] in
        let Qinv = self.leftInverse
        let d = self.diagonal
        let r = self.rank
        
        return (0 ..< r).map { (i) -> ColVector<R, n> in
            let v = Qinv * ColVector<R, n>.unit(size:self.rows, i)
            return d[i] * v
        }
    }()
}

private enum EliminationStep<R: EuclideanRing> {
    case AddRow(at: Int, to: Int, mul: R)
    case InvRow(Int)
    case SwapRows(Int, Int)
    case AddCol(at: Int, to: Int, mul: R)
    case InvCol(Int)
    case SwapCols(Int, Int)
    
    func applyTo<n: _Int, m: _Int>(_ A: inout Matrix<R, n, m>) {
        switch self {
        case let .AddRow(i, j, r):
            A.addRow(at: i, to: j, multipliedBy: r)
        case let .InvRow(i):
            A.multiplyRow(at: i, by: -1)
        case let .SwapRows(i, j):
            A.swapRows(i, j)
        case let .AddCol(i, j, r):
            A.addCol(at: i, to: j, multipliedBy: r)
        case let .InvCol(i):
            A.multiplyCol(at: i, by: -1)
        case let .SwapCols(i, j):
            A.swapCols(i, j)
        }
    }
    
    func applyInverseTo<n: _Int, m: _Int>(_ A: inout Matrix<R, n, m>) {
        switch self {
        case let .AddRow(i, j, r):
            A.addRow(at: i, to: j, multipliedBy: -r)
        case let .AddCol(i, j, r):
            A.addCol(at: i, to: j, multipliedBy: -r)
        case _:
            applyTo(&A)
        }
    }
}

fileprivate struct EliminationProcess<R: EuclideanRing, n: _Int, m: _Int> {
    let mode: EliminationMode
    var result: Matrix<R, n, m>
    var process: [EliminationStep<R>]
    var itr = 0
    
    init(_ target: Matrix<R, n, m>, _ mode: EliminationMode = .Both) {
        self.mode = mode
        self.result = target
        self.process = []
        run()
    }
    
    mutating func run() {
        guard var (a, i0, j0) = findNextMinNonZero() else { // when A = O
            return
        }
        
        let doRows = (mode != .ColsOnly)
        let doCols = (mode != .RowsOnly)
        
        process: while(true) {
            if doRows && !eliminateRow(&i0, j0) {
                continue process
            }
            if doCols && !eliminateCol(i0, &j0) {
                continue process
            }
            
            a = result[i0, j0]
            
            for i in itr ..< result.rows {
                for j in itr ..< result.cols {
                    if (i, j) == (i0, j0) {
                        continue
                    }
                    
                    let b = result[i, j]
                    
                    if b == 0 {
                        continue
                    }
                    
                    if b % a != 0 {
                        if doRows {
                            self.apply(.AddRow(at: i, to: i0, mul: 1))
                        } else {
                            self.apply(.AddCol(at: j, to: j0, mul: 1))
                        }
                        continue process
                    }
                }
            }
            break process
        }
        
        // TODO maybe implement NumberType or Comparable
        if R.self == IntegerNumber.self && (result[i0, j0] as! IntegerNumber) < 0 {
            if doRows {
                self.apply(.InvRow(i0))
            } else {
                self.apply(.InvCol(j0))
            }
        }
        
        if doRows && i0 > itr {
            self.apply(.SwapRows(itr, i0))
        }
        
        if doCols && j0 > itr {
            self.apply(.SwapCols(itr, j0))
        }
        
        if itr < min(result.rows, result.cols) - 1 {
            itr += 1
            run()
        }
    }
    
    mutating func apply(_ s: EliminationStep<R>) {
        s.applyTo(&result)
        process.append(s)
    }
    
    private mutating func eliminateRow(_ i0: inout Int, _ j0: Int) -> Bool {
        let a = result[i0, j0]
        
        for i in itr ..< result.rows {
            if i == i0 {
                continue
            }
            
            let b = result[i, j0]
            if b == 0 {
                continue
            }
            
            let (q, r) = b /% a
            
            self.apply(.AddRow(at: i0, to: i, mul: -q))
            
            if r != 0 {
                i0 = i
                return false
            }
        }
        
        return true
    }
    
    private mutating func eliminateCol(_ i0: Int, _ j0: inout Int) -> Bool {
        let a = result[i0, j0]
        
        for j in itr ..< result.cols {
            if j == j0 {
                continue
            }
            
            let b = result[i0, j]
            if b == 0 {
                continue
            }
            
            let (q, r) = b /% a
            
            self.apply(.AddCol(at: j0, to: j, mul: -q))
            
            if r != 0 {
                j0 = j
                return false
            }
        }
        
        return true
    }
    
    private func findNextMinNonZero() -> (value: R, row: Int, col: Int)? {
        return result.reduce(nil) { (result, current) -> (R, Int, Int)? in
            let (a, i, j) = current
            if i < itr || j < itr {
                return result
            }
            
            if a != 0 && (result == nil || a.degree < result!.0.degree) {
                return current
            } else {
                return result
            }
        }
    }
}
