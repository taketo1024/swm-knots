import Foundation

public struct Q: Field, CustomStringConvertible {
    public let p, q: Z
    
    public init(_ p: Z, _ q: Z) {
        if q == 0 {
            fatalError("denom: 0")
        }
        self.p = p
        self.q = q
    }
    
    public init(_ n: Z) {
        self.p = n
        self.q = 1
    }
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(Z(value))
    }
    
    public var description: String {
        switch q {
        case 1:  return "\(p)"
        case -1: return "\(-p)"
        default: return "\(p)/\(q)"
        }
    }
    
    public func reduce() -> Q {
        let d = gcd(p, q)
        return Q(p / d, q / d)
    }
}

public func ==(lhs: Q, rhs: Q) -> Bool {
    return lhs.p * rhs.q == lhs.q * rhs.p
}

public func +(lhs: Q, rhs: Q) -> Q {
    return Q(lhs.p * rhs.q + lhs.q * rhs.p, lhs.q * rhs.q).reduce()
}

public prefix func -(lhs: Q) -> Q {
    return Q(-lhs.p, lhs.q)
}

public func -(lhs: Q, rhs: Q) -> Q {
    return Q(lhs.p * rhs.q - lhs.q * rhs.p, lhs.q * rhs.q).reduce()
}

public func *(lhs: Q, rhs: Q) -> Q {
    return Q(lhs.p * rhs.p, lhs.q * rhs.q).reduce()
}

public func /(lhs: Q, rhs: Q) -> Q {
    return Q(lhs.p * rhs.q, lhs.q * rhs.p).reduce()
}