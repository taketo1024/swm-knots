import Foundation

public typealias RealNumber = Double

extension RealNumber: Field {
    public init(intValue n: IntegerNumber) {
        self.init(n)
    }
    
    public init(rationalValue r: RationalNumber) {
        self.init( RealNumber(r.p) / RealNumber(r.q) )
    }
    
    public var abs: RealNumber {
        return Swift.abs(self)
    }
    
    public var inverse: RealNumber? {
        return (self != 0) ? 1 / self : nil
    }
    
    public static var symbol: String {
        return "R"
    }
}

public let π = RealNumber.pi
