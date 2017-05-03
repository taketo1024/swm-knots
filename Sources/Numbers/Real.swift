import Foundation

public typealias RealNumber = Double

extension RealNumber: Field {
    public var inverse: RealNumber {
        return 1 / self
    }
}
