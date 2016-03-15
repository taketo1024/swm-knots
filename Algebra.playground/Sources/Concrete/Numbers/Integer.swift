import Foundation

public typealias Z = Int

extension Z: Ring { }

extension Z: EuclideanRing {
    public var degree: Int {
        return abs(self)
    }
    
    public func euclideanDiv(rhs: Z) -> (q: Z, r: Z) {
        let q = self / rhs
        return (q: q, r: self - q * rhs)
    }
}