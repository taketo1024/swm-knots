import Foundation

public protocol Group {
    static func *(lhs: Self, rhs: Self) -> Self
    static var identity: Self {get}
    var inverse: Self {get}
}