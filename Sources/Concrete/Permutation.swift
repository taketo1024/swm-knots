import Foundation

public struct Permutation<n: _Int>: Group {
    public var degree: Int { return n.intValue }
    fileprivate var elements: [Int] //
    
    private init(elements: [Int]) {
        let set = Set(elements)
        guard let min = set.min(),
              let max = set.max(),
              set.count == n.intValue && min == 0 && max == n.intValue - 1 else {
                fatalError("invalid input: \(elements)")
        }
        self.elements = elements
    }
    
    public init(_ dict: [Int: Int]) {
        self.init({ dict[$0] ?? $0 })
    }
    
    public init(_ cyclic: Int...) {
        self.init({ cyclic.index(of: $0).flatMap({ i in cyclic[(i + 1) % cyclic.count]}) ?? $0 })
    }
    
    public init(_ gen: ((Int) -> Int)) {
        let elements = (0 ..< n.intValue).map(gen)
        self.init(elements: elements)
    }
    
    public subscript(i: Int) -> Int {
        return elements[i]
    }
    
    public static var identity: Permutation<n> {
        return Permutation<n>{ $0 }
    }
    
    public var inverse: Permutation<n> {
        let inv = (0 ..< degree).sorted { self[$0] < self[$1] }
        return Permutation(elements: inv)
    }
    
    public func apply(i: Int) -> Int {
        return self[i]
    }
    
    public static var all: [Permutation<n>] {
        return rawPermutation(n.intValue).map{ Permutation(elements: $0) }
    }
}

public func == <n: _Int>(a: Permutation<n>, b: Permutation<n>) -> Bool {
    return a.elements == b.elements
}

public func * <n: _Int>(a: Permutation<n>, b: Permutation<n>) -> Permutation<n> {
    return Permutation{ a[b[$0]] }
}

public func sgn<n: _Int>(_ s: Permutation<n>) -> Int {
    switch n.intValue {
    case 0, 1:
        return 1
    case let l:
        let r = (0 ..< l - 1)
            .flatMap{ i in (i + 1 ..< l).map{ j in (i, j) } }
            .reduce((1, 1)) {
                (r: (Int, Int), pair: (Int, Int)) -> (Int, Int) in
                return (r.0 * (pair.0 - pair.1) , r.1 * (s[pair.0] - s[pair.1]))
            }
        return r.0 / r.1
    }
}

extension Permutation: CustomStringConvertible {
    public var description: String {
        return "(" + (0 ..< degree).map({ i in
            return "\(i): \(self[i])"
        }).joined(separator: ", ") + ")"
    }
}

internal func rawPermutation(_ n: Int) -> [[Int]] {
    switch n {
    case 0:
        return [[]]
    default:
        let prev = rawPermutation(n - 1)
        return (0 ..< n).flatMap({ (i: Int) -> [[Int]] in
            prev.map({ (s: [Int]) -> [Int] in
                [i] + s.map{ $0 < i ? $0 : $0 + 1 }
            })
        })
    }
}
