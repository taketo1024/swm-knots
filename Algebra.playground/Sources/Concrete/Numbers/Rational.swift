import Foundation

public struct Q: Field {
    public let p, q: Z
    
    public init(_ p: Z, _ q: Z) {
        guard q != 0 else {
            fatalError("denom: 0")
        }
        self.p = p
        self.q = q
    }
    
    public init(_ n: Z) {
        self.init(n, 1)
    }
    
    public var inverse: Q {
        return Q(q, p)
    }
    
    public var reduced: Q {
        let d = abs(gcd(p, q)) * (q / abs(q))
        return Q(p / d, q / d)
    }
}

public func ==(lhs: Q, rhs: Q) -> Bool {
    return lhs.p * rhs.q == lhs.q * rhs.p
}

public func +(lhs: Q, rhs: Q) -> Q {
    return Q(lhs.p * rhs.q + lhs.q * rhs.p, lhs.q * rhs.q)
}

public prefix func -(lhs: Q) -> Q {
    return Q(-lhs.p, lhs.q)
}

public func -(lhs: Q, rhs: Q) -> Q {
    return Q(lhs.p * rhs.q - lhs.q * rhs.p, lhs.q * rhs.q)
}

public func *(lhs: Q, rhs: Q) -> Q {
    return Q(lhs.p * rhs.p, lhs.q * rhs.q)
}

public func /(lhs: Q, rhs: Q) -> Q {
    return Q(lhs.p * rhs.q, lhs.q * rhs.p)
}

extension Q: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension Q: CustomStringConvertible {
    public var description: String {
        let r = reduced
        switch r.q {
        case 1:  return "\(r.p)"
        default: return "\(r.p)/\(r.q)"
        }
    }
}