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
    
    private lazy var _result: (Matrix<R, n, m>, [EliminationStep<R>]) = {[unowned self] in
        var e = EliminationProcessor(self.target, self.mode)
        e.run()
        return (e.result, e.process)
    }()
    
    public  lazy var result:  Matrix<R, n, m>      = self._result.0
    private lazy var process: [EliminationStep<R>] = self._result.1
    
    public lazy var left: Matrix<R, n, n> = {[unowned self] in
        var Q = self.target.leftIdentity
        for s in self.process {
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
        for s in self.process.reversed() {
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
        for s in self.process {
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
        for s in self.process.reversed() {
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
    
    public lazy var kernelPart: Matrix<R, m, _TypeLooseSize> = { [unowned self] in
        return self.right.submatrix(colsInRange: self.rank ..< self.cols)
    }()
    
    public lazy var kernelVectors: [ColVector<R, m>] = { [unowned self] in
        return self.kernelPart.toColVectors()
    }()
    
    public lazy var imagePart: Matrix<R, n, _TypeLooseSize> = { [unowned self] in
        return self.leftInverse.submatrix(colsInRange: 0 ..< self.rank)
    }()
    
    public lazy var imageVectors: [ColVector<R, n>] = { [unowned self] in
        return self.imagePart.toColVectors()
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

fileprivate struct EliminationProcessor<R: EuclideanRing, n: _Int, m: _Int> {
    let mode: EliminationMode
    let rows: Int
    let cols: Int
    var result: Matrix<R, n, m>
    var process: [EliminationStep<R>]
    var itr = 0
    
    init(_ target: Matrix<R, n, m>, _ mode: EliminationMode = .Both) {
        self.mode = mode
        self.rows = target.rows
        self.cols = target.cols
        self.result = target
        self.process = []
    }
    
    mutating func run() {
        let doRows = (mode != .ColsOnly)
        let doCols = (mode != .RowsOnly)
        let maxItr = (mode == .Both)     ? min(rows, cols) :
                     (mode == .RowsOnly) ? rows : cols
        
        iteration: while itr < maxItr {
            guard var (_, i0, j0) = findNextMinNonZero() else {
                break iteration
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

            itr += 1
        }
        
        // post process
        postProcess()
    }
    
    mutating func apply(_ s: EliminationStep<R>) {
        s.applyTo(&result)
        process.append(s)
    }
    
    private mutating func eliminateRow(_ i0: inout Int, _ j0: Int) -> Bool {
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
        
        if mode == .RowsOnly {
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
    
    private mutating func eliminateCol(_ i0: Int, _ j0: inout Int) -> Bool {
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
        
        if mode == .ColsOnly {
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
    
    private func findNextMinNonZero() -> (value: R, row: Int, col: Int)? {
        var next: (value: R, row: Int, col: Int)? = nil
        
        func update(_ i: Int, _ j: Int) {
            let a = result[i, j]
            if a != 0 && (next == nil || a.degree < next!.0.degree) {
                next = (a, i, j)
            }
        }
        
        switch mode {
        case .Both:
            for i in itr ..< rows {
                for j in itr ..< cols {
                    update(i, j)
                }
            }
        case .RowsOnly:
            for i in itr ..< rows {
                for j in 0 ..< cols {
                    update(i, j)
                }
            }
        case .ColsOnly:
            for j in itr ..< cols {
                for i in 0 ..< rows {
                    update(i, j)
                }
            }
        }
        
        return next
    }
    
    private mutating func postProcess() {
        switch mode {
        case .RowsOnly:
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
        case .ColsOnly:
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
}
