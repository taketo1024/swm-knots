import Foundation

public protocol Module: AdditiveGroup {
    associatedtype R: Ring
    static func * (r: R, m: Self) -> Self
    static func * (m: Self, r: R) -> Self
}
