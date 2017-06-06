import Foundation

public typealias IntegerNumber = Int

extension IntegerNumber: EuclideanRing {
    public init(intValue n: IntegerNumber) {
        self.init(n)
    }
    
    public var degree: Int {
        return abs(self)
    }
    
    public var isUnit: Bool {
        return abs(self) == 1
    }
    
    public var unitInverse: IntegerNumber? {
        return isUnit ? self : nil
    }
    
    public static func eucDiv(_ a: IntegerNumber, _ b: IntegerNumber) -> (q: IntegerNumber, r: IntegerNumber) {
        let q = a / b
        return (q: q, r: a - q * b)
    }
    
    public static var symbol: String {
        return "Z"
    }
    
    public var evenOddSign: Int {
        return (self % 2 == 0) ? 1 : -1
    }
}

public struct IntegerIdeal<n: _Int>: EuclideanIdeal {
    public typealias Super = IntegerNumber
    
    public static var generator: IntegerNumber {
        return n.intValue
    }
    
    public let a: IntegerNumber
    
    public init(_ a: IntegerNumber) {
        self.a = a
    }
    
    public var asSuper: IntegerNumber {
        return a
    }
}

public struct IntegerQuotientRing<n: _Int>: QuotientRingType, FiniteSetType {
    public typealias Sub = IntegerIdeal<n>
    
    private let a: Base
    
    public init(_ a: Base) {
        self.a = Sub.reduced(a)
    }
    
    public var representative: IntegerNumber {
        return a
    }
    
    public static var allElements: [IntegerQuotientRing<n>] {
        return (0 ..< n.intValue).map{ IntegerQuotientRing<n>($0) }
    }
    
    public static var countElements: Int {
        return n.intValue
    }
}

// TODO merge with IntegerQuotientRing after conditional conformance is supported.
public struct IntegerQuotientField<n: _Prime>: QuotientFieldType, FiniteSetType {
    public typealias Sub = IntegerIdeal<n>
    
    private let a: Base
    
    public init(_ a: Base) {
        self.a = Sub.reduced(a)
    }
    
    public var representative: IntegerNumber {
        return a
    }
    
    public static var allElements: [IntegerQuotientField<n>] {
        return (0 ..< n.intValue).map{ IntegerQuotientField<n>($0) }
    }
    
    public static var countElements: Int {
        return n.intValue
    }
}
