import Foundation

public struct RationalNumber: Field {
    public let p, q: Integer
    
    public init(_ p: Integer, _ q: Integer) {
        guard q != 0 else {
            fatalError("denom: 0")
        }
        self.p = p
        self.q = q
    }
    
    public init(_ n: Integer) {
        self.init(n, 1)
    }
    
    public var inverse: RationalNumber {
        return RationalNumber(q, p)
    }
    
    public var reduced: RationalNumber {
        let d = abs(gcd(p, q)) * (q / abs(q))
        return RationalNumber(p / d, q / d)
    }
}

public func ==(a: RationalNumber, b: RationalNumber) -> Bool {
    return a.p * b.q == a.q * b.p
}

public func +(a: RationalNumber, b: RationalNumber) -> RationalNumber {
    return RationalNumber(a.p * b.q + a.q * b.p, a.q * b.q)
}

public prefix func -(a: RationalNumber) -> RationalNumber {
    return RationalNumber(-a.p, a.q)
}

public func -(a: RationalNumber, b: RationalNumber) -> RationalNumber {
    return RationalNumber(a.p * b.q - a.q * b.p, a.q * b.q)
}

public func *(a: RationalNumber, b: RationalNumber) -> RationalNumber {
    return RationalNumber(a.p * b.p, a.q * b.q)
}

public func /(a: RationalNumber, b: RationalNumber) -> RationalNumber {
    return RationalNumber(a.p * b.q, a.q * b.p)
}

extension RationalNumber: CustomStringConvertible {
    public var description: String {
        let r = reduced
        switch r.q {
        case 1:  return "\(r.p)"
        default: return "\(r.p)/\(r.q)"
        }
    }
}