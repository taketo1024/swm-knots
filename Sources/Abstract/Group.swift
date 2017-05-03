import Foundation

public protocol Group: Monoid {
    var inverse: Self { get }
}

public func ** <G: Group>(a: G, b: Int) -> G {
    switch b {
    case let n where n > 0:
        return a * (a ** (n - 1))
    case let n where n < 0:
        return a.inverse * (a ** (n + 1))
    default:
        return G.identity
    }
}
