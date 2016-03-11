import Foundation

public struct RationalNumber: Field {
    public let p, q: Integer
    
    public init(_ p: Integer, _ q: Integer) {
        if q == 0 {
            fatalError("denom: 0")
        }
        self.p = p
        self.q = q
    }
    
    public init(_ n: Integer) {
        self.p = n
        self.q = 1
    }
    
    public func reduce() -> RationalNumber {
        let d = gcd(p, q)
        return RationalNumber(p / d, q / d)
    }
}

public func ==(lhs: RationalNumber, rhs: RationalNumber) -> Bool {
    return lhs.p * rhs.q == lhs.q * rhs.p
}

public func +(lhs: RationalNumber, rhs: RationalNumber) -> RationalNumber {
    return RationalNumber(lhs.p * rhs.q + lhs.q * rhs.p, lhs.q * rhs.q).reduce()
}

public prefix func -(lhs: RationalNumber) -> RationalNumber {
    return RationalNumber(-lhs.p, lhs.q)
}

public func -(lhs: RationalNumber, rhs: RationalNumber) -> RationalNumber {
    return RationalNumber(lhs.p * rhs.q - lhs.q * rhs.p, lhs.q * rhs.q).reduce()
}

public func *(lhs: RationalNumber, rhs: RationalNumber) -> RationalNumber {
    return RationalNumber(lhs.p * rhs.p, lhs.q * rhs.q).reduce()
}

public func /(lhs: RationalNumber, rhs: RationalNumber) -> RationalNumber {
    return RationalNumber(lhs.p * rhs.q, lhs.q * rhs.p).reduce()
}

extension RationalNumber: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(Integer(value))
    }
}

extension RationalNumber: CustomStringConvertible {
    public var description: String {
        switch q {
        case 1:  return "\(p)"
        case -1: return "\(-p)"
        default: return "\(p)/\(q)"
        }
    }
}