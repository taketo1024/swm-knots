import Foundation

public typealias R = Double

extension R: Field {
    public var inverse: R {
        return 1 / self
    }
}
