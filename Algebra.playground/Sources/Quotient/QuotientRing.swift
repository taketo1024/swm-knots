import Foundation

public protocol PrincipalIdeal {
    typealias R: Ring
    static var generator: R {get}
}

public protocol EuclideanPrincipalIdeal: PrincipalIdeal {
    typealias R: EuclideanRing
    static var generator: R {get}
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

public func ==<R: EuclideanQuotientRing>(lhs: R, rhs: R) -> Bool {
    return (lhs.value - rhs.value) % lhs.mod == R.I.R(0)
}

public func +<R: EuclideanQuotientRing>(lhs: R, rhs: R) -> R {
    return R(lhs.value + rhs.value)
}

public prefix func -<R: EuclideanQuotientRing>(lhs: R) -> R {
    return R(-lhs.value)
}

public func *<R: EuclideanQuotientRing>(lhs: R, rhs: R) -> R {
    return R(lhs.value * rhs.value)
}
