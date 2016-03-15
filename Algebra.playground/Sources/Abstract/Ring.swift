import Foundation

public protocol Ring: AdditiveGroup, Monoid {
    init(_ intValue: Int)
}

public extension Ring {
    static var zero: Self {
        return Self.init(0)
    }
    
    static var identity: Self {
        return Self.init(1)
    }
}