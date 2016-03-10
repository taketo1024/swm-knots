import Foundation

public struct SymGroup<n: TPInt>: Group {
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
    
    public static var identity: SymGroup<n> {
        return SymGroup<n>{ $0 }
    }
    
    public var inverse: SymGroup<n> {
        let inv = (0 ..< degree).sort{ self[$0] < self[$1] }
        return SymGroup(elements: inv)
    }
    
    public static var all: [SymGroup<n>] {
        return perm(n.value).map{ SymGroup(elements: $0) }
    }
}

extension SymGroup: CustomStringConvertible {
    public var description: String {
        return "(" + (0 ..< degree).map({ i in
            return "\(self[i])"
        }).joinWithSeparator(", ") + ")"
    }
}

public func *<n: TPInt>(lhs: SymGroup<n>, rhs: SymGroup<n>) -> SymGroup<n> {
    return SymGroup{ lhs[rhs[$0]] }
}

public func sgn<n: TPInt>(s: SymGroup<n>) -> Int {
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