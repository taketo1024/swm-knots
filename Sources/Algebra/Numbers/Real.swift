import Foundation

public struct RealNumber: Subfield, NormedSpace, Comparable, ExpressibleByFloatLiteral {
    public typealias Super = ComplexNumber
    public typealias FloatLiteralType = Double
    
    internal let value: Double
    public let error: Double
    
    public init(floatLiteral x: Double) {
        self.init(x)
    }
    
    public init(intValue x: Int) {
        self.init(x)
    }
    
    public init(rationalValue r: RationalNumber) {
        self.init(r)
    }
    
    public init(_ x: Int) {
        self.init(Double(x))
    }
    
    public init(_ r: RationalNumber) {
        self.init(Double(r.p) / Double(r.q))
    }
    
    public init(_ value: Double) {
        self.init(value, value.ulp)
    }
    
    private init(_ value: Double, _ error: Double) {
        self.value = value
        self.error = error
    }
    
    public init(_ z: ComplexNumber) {
        assert(RealNumber.contains(z))
        self.init(z.real.value)
    }
    
    public var norm: RealNumber {
        return RealNumber( sqrt(value * value) )
    }
    
    public var inverse: RealNumber? {
        // 1/(x + e) ~ 1/x - (1/x^2)e + ...
        return RealNumber(1/value, error / (value * value))
    }
    
    public static func ==(a: RealNumber, b: RealNumber) -> Bool {
//        print(fabs(a.value - b.value), "<=", max(a.error, b.error), ":", fabs(a.value - b.value) < max(a.error, b.error))
        return fabs(a.value - b.value) <= max(a.error, b.error)
    }
    
    public static func +(a: RealNumber, b: RealNumber) -> RealNumber {
        return RealNumber(a.value + b.value, a.error + b.error)
    }
    
    public static prefix func -(a: RealNumber) -> RealNumber {
        return RealNumber(-a.value, a.error)
    }
    
    public static func *(a: RealNumber, b: RealNumber) -> RealNumber {
        return RealNumber(a.value * b.value, a.error * fabs(b.value) + b.error * fabs(a.value))
    }
    
    public static func <(lhs: RealNumber, rhs: RealNumber) -> Bool {
        return lhs.value < rhs.value
    }
    
    public var asDouble: Double {
        return value
    }
    
    public var asSuper: ComplexNumber {
        return ComplexNumber(self, .zero)
    }
    
    public static func contains(_ z: ComplexNumber) -> Bool {
        return z.imaginary == .zero
    }
    
    public var hashValue: Int {
        return value.hashValue
    }
    
    public var description: String {
        return value.description
    }
    
    public static var symbol: String {
        return "R"
    }
}

public let π = RealNumber(Double.pi)

public func exp(_ x: RealNumber) -> RealNumber {
    return RealNumber(exp(x.value))
}

public func sin(_ x: RealNumber) -> RealNumber {
    return RealNumber(sin(x.value))
}

public func cos(_ x: RealNumber) -> RealNumber {
    return RealNumber(cos(x.value))
}

public func tan(_ x: RealNumber) -> RealNumber {
    return RealNumber(tan(x.value))
}

public func asin(_ x: RealNumber) -> RealNumber {
    return RealNumber(asin(x.value))
}

public func acos(_ x: RealNumber) -> RealNumber {
    return RealNumber(acos(x.value))
}

public func atan(_ x: RealNumber) -> RealNumber {
    return RealNumber(atan(x.value))
}

public func sqrt(_ x: RealNumber) -> RealNumber {
    return RealNumber(sqrt(x.value))
}
