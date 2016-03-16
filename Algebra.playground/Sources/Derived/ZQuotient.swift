import Foundation

// common protocol used in Z_<n> and F_<n>

public protocol ZQuotient: Ring, CustomStringConvertible {
    typealias n: TPInt
    var mod: Int {get}
    var a: Z {get}
}

extension ZQuotient {
    public var mod: Int {
        return n.value
    }
    
    public var reduced: Self {
        let b = a % mod
        return Self.init( (b >= 0) ? b : b + mod )
    }
    
    public var description: String {
        let r = reduced
        return "\(r.a)"
    }
}

public func ==<R: ZQuotient>(lhs: R, rhs: R) -> Bool {
    return (lhs.a - rhs.a) % lhs.mod == 0
}

public func +<R: ZQuotient>(lhs: R, rhs: R) -> R {
    return R(lhs.a + rhs.a)
}

public prefix func -<R: ZQuotient>(lhs: R) -> R {
    return R(-lhs.a)
}

public func *<R: ZQuotient>(lhs: R, rhs: R) -> R {
    return R(lhs.a * rhs.a)
}

public struct Z_<k: TPInt>: ZQuotient, IntegerLiteralConvertible {
    public typealias n = k
    
    public let a: Z
    
    public init(_ a: Int) {
        self.a = a
    }
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

public struct F_<p: TPInt>: ZQuotient, Field, IntegerLiteralConvertible {
    public typealias n = p
    
    public let a: Z
    
    public init(_ a: Int) {
        self.a = a
    }
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
    
    public var inverse: F_<p> {
        guard a != 0 else {
            fatalError("0-inverse")
        }
        
        // find: p * x + a * y = 1
        // then: a^-1 = y (mod p)

        let res = euclideanAlgorithm(mod, a)
        guard res.r == 1 else {
            fatalError("modular: \(p.value) is non-prime.")
        }
        
        return F_(res.q1)
    }
}
