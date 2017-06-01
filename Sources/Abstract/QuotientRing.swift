import Foundation

public protocol QuotientRing: Ring {
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
    public static func == (a: Self, b: Self) -> Bool {
        return (a.value - b.value) % a.mod == 0
    }
    
    public static func + (a: Self, b: Self) -> Self {
        return Self.init(a.value + b.value)
    }
    
    public static prefix func - (a: Self) -> Self {
        return Self.init(-a.value)
    }
    
    public static func * (a: Self, b: Self) -> Self {
        return Self.init(a.value * b.value)
    }
    
    public var description: String {
        return "[\(value)]"
    }
    
    public var detailDescription: String {
        return "(\(value) mod \(mod))"
    }
}

