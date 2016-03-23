import Foundation

public protocol IntIdeal: EuclideanPrincipalIdeal {
    typealias R = Integer
}

public struct IntQuotient<P: IntIdeal where P.R == Integer>: EuclideanQuotientRing {
    public typealias I = P
    public let value: Integer
    
    public init(_ value: Integer) {
        self.value = value
    }
}

public struct IntQuotientField<P: IntIdeal where P.R == Integer>: EuclideanQuotientRing, Field {
    public typealias I = P
    public let value: Integer
    
    public init(_ value: Integer) {
        self.value = value
    }
    
    public var inverse: IntQuotientField<P> {
        let (x, _, _) = bezout(value, mod)
        return IntQuotientField(x)
    }
}

