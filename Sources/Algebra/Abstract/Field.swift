import Foundation

public protocol Field: EuclideanRing {
    init(rationalValue r: RationalNumber)
}

public extension Field {
    public init(rationalValue r: RationalNumber) {
        fatalError("TODO")
    }
    
    public var normalizeUnit: Self {
        return self.inverse!
    }
    
    public var degree: Int {
        return self == .zero ? 0 : 1
    }
    
    public static func / (a: Self, b: Self) -> Self {
        return a * b.inverse!
    }
    
    public static func ** (a: Self, b: Int) -> Self {
        switch b {
        case let n where n > 0:
            return a * (a ** (n - 1))
        case let n where n < 0:
            return a.inverse! * (a ** (n + 1))
        default:
            return .identity
        }
    }
    
    public static func eucDiv(_ a: Self, _ b: Self) -> (q: Self, r: Self) {
        return (a/b, 0)
    }
    
    public static var isField: Bool {
        return true
    }
}
