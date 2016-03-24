import Foundation

public protocol Ring: AdditiveGroup, Monoid, IntegerLiteralConvertible {
    typealias IntegerLiteralType = Int
    init(_ intValue: Int)
}

public extension Ring {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
    
    static var zero: Self {
        return Self.init(0)
    }
    
    static var identity: Self {
        return Self.init(1)
    }
}
