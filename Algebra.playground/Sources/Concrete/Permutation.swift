import Foundation

public struct Permutation<n: TPInt>: Group {
    public var degree: Int { return n.value }
    
    private var elements: [Int]
    
    private init(elements: [Int]) {
        let set = Set(elements)
        guard let min = set.minElement(), max = set.maxElement()
            where set.count == n.value && min == 0 && max == n.value - 1 else {
                fatalError()
        }
        self.elements = elements
    }
    
    public init(_ elements: Int...) {
        self.init(elements: elements)
    }
    
    public init(_ gen: (Int) -> Int) {
        let elements = (0 ..< n.value).map(gen)
        self.init(elements: elements)
    }
    
    public subscript(i: Int) -> Int {
        return elements[i]
    }
    
    public static var identity: Permutation<n> {
        return Permutation<n>{ $0 }
    }
    
    public var inverse: Permutation<n> {
        let inv = (0 ..< degree).sort{ self[$0] < self[$1] }
        return Permutation(elements: inv)
    }
    
    public static var all: [Permutation<n>] {
        return perm(n.value).map{ Permutation(elements: $0) }
    }
}

public func ==<n: TPInt>(a: Permutation<n>, b: Permutation<n>) -> Bool {
    return a.elements == b.elements
}

public func *<n: TPInt>(a: Permutation<n>, b: Permutation<n>) -> Permutation<n> {
    return Permutation{ a[b[$0]] }
}

public func sgn<n: TPInt>(s: Permutation<n>) -> Int {
    switch n.value {
    case 0, 1:
        return 1
    case let l:
        let r = (0 ..< l - 1)
            .flatMap{ i in (i + 1 ..< l).map{j in (i, j)} }
            .reduce((1, 1), combine: {
                (r: (Int, Int), pair: (Int, Int)) -> (Int, Int) in
                return (r.0 * (pair.0 - pair.1) , r.1 * (s[pair.0] - s[pair.1]))
            })
        return r.0 / r.1
    }
}

extension Permutation: CustomStringConvertible {
    public var description: String {
        return "(" + (0 ..< degree).map({ i in
            return "\(self[i])"
        }).joinWithSeparator(", ") + ")"
    }
}