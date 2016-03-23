import Foundation

public protocol PrincipalIdeal {
    typealias R: Ring
    static var generator: R { get }
}

public protocol EuclideanPrincipalIdeal: PrincipalIdeal {
    typealias R: EuclideanRing
    static var generator: R { get }
}

public protocol QuotientRing: Ring {
    typealias I: PrincipalIdeal
    init(_ r: I.R)
}

public protocol EuclideanQuotientRing: QuotientRing, CustomStringConvertible {
    typealias I: EuclideanPrincipalIdeal
    typealias R = I.R
    
    var value: I.R { get }
    var mod: I.R { get }
    var reduced: Self { get }
}

extension EuclideanQuotientRing {
    public var mod: I.R {
        return I.generator
    }
    
    public var reduced: Self {
        let r = value % mod
        return Self.init(r)
    }
    
    public var description: String {
        return "\(value % mod) mod \(mod)"
    }
}

public func == <R: EuclideanQuotientRing>(a: R, b: R) -> Bool {
    return (a.value - b.value) % a.mod == R.I.R(0)
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
