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

public func ==(a: Q, b: Q) -> Bool {
    return a.p * b.q == a.q * b.p
}

public func +(a: Q, b: Q) -> Q {
    return Q(a.p * b.q + a.q * b.p, a.q * b.q)
}

public prefix func -(a: Q) -> Q {
    return Q(-a.p, a.q)
}

public func -(a: Q, b: Q) -> Q {
    return Q(a.p * b.q - a.q * b.p, a.q * b.q)
}

public func *(a: Q, b: Q) -> Q {
    return Q(a.p * b.p, a.q * b.q)
}

public func /(a: Q, b: Q) -> Q {
    return Q(a.p * b.q, a.q * b.p)
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