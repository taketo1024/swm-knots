import Foundation

public struct Z_<n: TPInt>: Ring {
    var mod: Int {
        return n.value
    }
    
    public let a: Z
    
    public init(_ a: Int) {
        self.a = a
    }
    
    public var reduced: Z_<n> {
        return Z_(a % mod)
    }
}

public func ==<n: TPInt>(lhs: Z_<n>, rhs: Z_<n>) -> Bool {
    return (lhs.a - rhs.a) % n.value == 0
}

public func +<n: TPInt>(lhs: Z_<n>, rhs: Z_<n>) -> Z_<n> {
    return Z_<n>(lhs.a + rhs.a)
}

public prefix func -<n: TPInt>(lhs: Z_<n>) -> Z_<n> {
    return Z_<n>(-lhs.a)
}

public func *<n: TPInt>(lhs: Z_<n>, rhs: Z_<n>) -> Z_<n> {
    return Z_<n>(lhs.a * rhs.a)
}

extension Z_ : IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension Z_ : CustomStringConvertible {
    public var description: String {
        let r = reduced
        return "\(r.a)"
    }
}
