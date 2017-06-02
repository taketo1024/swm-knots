import Foundation

public typealias IntegerNumber = Int

extension IntegerNumber: EuclideanRing {
    public var degree: Int {
        return abs(self)
    }
    
    public static func eucDiv(_ a: IntegerNumber, _ b: IntegerNumber) -> (q: IntegerNumber, r: IntegerNumber) {
        let q = a / b
        return (q: q, r: a - q * b)
    }
    
    public static var symbol: String {
        return "Z"
    }
    
    public var evenOddSign: Int {
        return (self % 2 == 0) ? 1 : -1
    }
}

public struct IntegerIdeal<n: _Int>: EuclideanIdeal {
    public typealias Super = IntegerNumber
    
    public static var generator: IntegerNumber {
        return n.intValue
    }
    
    public let a: IntegerNumber
    
    public init(_ a: IntegerNumber) {
        self.a = a
    }
    
    public var asSuper: IntegerNumber {
        return a
    }
}

public typealias IntegerQuotientRing<n: _Int> = _QuotientRing<IntegerNumber, IntegerIdeal<n>>

