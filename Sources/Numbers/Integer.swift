import Foundation

public typealias IntegerNumber = Int

extension IntegerNumber: Ring {
}

extension IntegerNumber: EuclideanRing {
    public var degree: Int {
        return abs(self)
    }
    
    public static func eucDiv(_ a: IntegerNumber, _ b: IntegerNumber) -> (q: IntegerNumber, r: IntegerNumber) {
        let q = a / b
        return (q: q, r: a - q * b)
    }
}
