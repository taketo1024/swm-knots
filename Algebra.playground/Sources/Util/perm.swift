import Foundation

public func perm(n: Int) -> [[Int]] {
    switch n {
    case 0:
        return [[]]
    default:
        let prev = perm(n - 1)
        return (0 ..< n).flatMap({ (i: Int) -> [[Int]] in
            prev.map({ (s: [Int]) -> [Int] in
                [i] + s.map{ $0 < i ? $0 : $0 + 1 }
            })
        })
    }
}
