import Foundation

public protocol IntIdeal: EuclideanPrincipalIdeal {
    typealias R = IntegerNumber
}

public struct IntQuotient<P: IntIdeal>: EuclideanQuotientRing where P.R == IntegerNumber {
    public typealias I = P
    public let value: IntegerNumber
    
    public init(_ value: IntegerNumber) {
        self.value = value
    }
}

public struct IntQuotientField<P: IntIdeal>: EuclideanQuotientRing, Field where P.R == IntegerNumber {
    public typealias I = P
    public let value: IntegerNumber
    
    public init(_ value: IntegerNumber) {
        self.value = value
    }
    
    public var inverse: IntQuotientField<P> {
        let (x, _, _) = bezout(value, mod)
        return IntQuotientField(x)
    }
}
