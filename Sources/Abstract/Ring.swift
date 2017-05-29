import Foundation

public protocol Ring: AdditiveGroup, Monoid, ExpressibleByIntegerLiteral {
    associatedtype IntegerLiteralType = Int
    init(_ intValue: Int)
    var isUnit: Bool { get }
    static func matrixElimination<n:_Int, m:_Int>(_ A: Matrix<Self, n, m>, mode: MatrixEliminationMode) -> BaseMatrixElimination<Self, n, m>
}

public extension Ring {
    // required init from `ExpressibleByIntegerLiteral`
    public init(integerLiteral value: Int) {
        self.init(value)
    }
    
    public var isUnit: Bool {
        return (self == Self.identity) || (self == -Self.identity)
    }

    public static var zero: Self {
        return Self.init(0)
    }
    
    public static var identity: Self {
        return Self.init(1)
    }
    
    public static func **(a: Self, n: Int) -> Self {
        return (0 ..< n).reduce(Self.identity){ (res, _) in res * a }
    }
    
    // must override in subclass
    public static func matrixElimination<n:_Int, m:_Int>(_ A: Matrix<Self, n, m>, mode: MatrixEliminationMode) -> BaseMatrixElimination<Self, n, m> {
        return BaseMatrixElimination<Self, n, m>(A, mode: mode)
    }
}
