import Foundation

public protocol IntIdeal: EuclideanPrincipalIdeal {
    typealias R = Z
}

public struct IntQuotient<P: IntIdeal where P.R == Z>: EuclideanQuotientRing {
    public typealias I = P
    public let value: Z
    
    public init(_ value: Z) {
        self.value = value
    }
}

public struct IntQuotientField<P: IntIdeal where P.R == Z>: EuclideanQuotientRing, Field {
    public typealias I = P
    public let value: Z
    
    public init(_ value: Z) {
        self.value = value
    }
    
    public var inverse: IntQuotientField<P> {
        let (x, _, _) = bezout(value, mod)
        return IntQuotientField(x)
    }
}

