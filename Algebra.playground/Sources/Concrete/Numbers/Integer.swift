import Foundation

public typealias Integer = Int

extension Integer: Ring { }

extension Integer: EuclideanRing {
    public var degree: Int {
        return abs(self)
    }
    
    public static func eucDiv(a: Integer, _ b: Integer) -> (q: Integer, r: Integer) {
        let q = a / b
        return (q: q, r: a - q * b)
    }
}