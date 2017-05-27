import Foundation

public protocol QuotientRing: Ring, CustomStringConvertible {
    associatedtype R: Ring
    
    var value: R { get }
    var mod: R { get }
    
    init(_ r: R)
}

public protocol QuotientField: QuotientRing, Field {}

public protocol EuclideanQuotientRing: QuotientRing {
    associatedtype R: EuclideanRing
}

public protocol EuclideanQuotientField: EuclideanQuotientRing, QuotientField {}

extension EuclideanQuotientRing {
    public var description: String {
        return "[\(value)]"
    }
    
    public var detailDescription: String {
        return "(\(value) mod \(mod))"
    }
}

public func == <R: EuclideanQuotientRing>(a: R, b: R) -> Bool {
    return (a.value - b.value) % a.mod == 0
}

public func + <R: EuclideanQuotientRing>(a: R, b: R) -> R {
    return R(a.value + b.value)
}

public prefix func - <R: EuclideanQuotientRing>(a: R) -> R {
    return R(-a.value)
}

public func * <R: EuclideanQuotientRing>(a: R, b: R) -> R {
    return R(a.value * b.value)
}
