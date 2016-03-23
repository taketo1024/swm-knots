import Foundation

public typealias Z = Int

extension Z: Ring { }

extension Z: EuclideanRing {
    public var degree: Int {
        return abs(self)
    }
    
    public static func eucDiv(a: Z, _ b: Z) -> (q: Z, r: Z) {
        let q = a / b
        return (q: q, r: a - q * b)
    }
}