import Foundation

public typealias RealNumber = Double

extension RealNumber: Field {
    public init(intValue n: IntegerNumber) {
        self.init(n)
    }
    
    public var inverse: RealNumber {
        return 1 / self
    }
    
    public static var symbol: String {
        return "R"
    }
}
