import Foundation

public typealias Integer = Int

extension Integer: Ring {}

extension Integer: EuclideanRing {
    public var degree: Int {
        return abs(self)
    }
    
    public func euclideanDiv(rhs: Integer) -> (q: Integer, r: Integer) {
        let q = self / rhs
        return (q: q, r: self - q * rhs)
    }
}