import Foundation

public struct Permutation<n: _Int>: Group, FiniteType, CustomStringConvertible {
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
    
    public init(cyclic: Int...) {
        self.init(cyclic: cyclic)
    }
    
    internal init(cyclic: [Int]) {
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
    
    public func apply(_ i: Int) -> Int {
        return self[i]
    }
    
    public var signature: Int {
        switch n.intValue {
        case 0, 1:
            return 1
        case let l:
            let r = (0 ..< l - 1)
                .flatMap{ i in (i + 1 ..< l).map{ j in (i, j) } }
                .reduce((1, 1)) {
                    (r: (Int, Int), pair: (Int, Int)) -> (Int, Int) in
                    return (r.0 * (pair.0 - pair.1) , r.1 * (self[pair.0] - self[pair.1]))
            }
            return r.0 / r.1
        }
    }
    
    private var rawCyclicDecomposition: [[Int]] {
        var list = Array(0 ..< n.intValue)
        var result: [[Int]] = []
        
        while !list.isEmpty {
            let a = list.first!
            var cyclic: [Int] = []
            var x = a
            
            while !cyclic.contains(x) {
                list.remove(at: list.index(of: x)!)
                cyclic.append(x)
                x = apply(x)
            }
            
            if cyclic.count > 1 {
                result.append(cyclic)
            }
        }
        
        return result
    }
    
    public var cyclicDecomposition: [Permutation<n>] {
        return rawCyclicDecomposition.map{ Permutation<n>(cyclic: $0) }
    }
    
    public static var allElements: [Permutation<n>] {
        return n.intValue.permutations.map{ Permutation(elements: $0) }
    }
    
    public static var countElements: Int {
        return n.intValue.factorial
    }
    
    public static func == (a: Permutation<n>, b: Permutation<n>) -> Bool {
        return a.elements == b.elements
    }
    
    public static func * (a: Permutation<n>, b: Permutation<n>) -> Permutation<n> {
        return Permutation{ a[b[$0]] }
    }
    
    public var description: String {
        let desc = rawCyclicDecomposition.map{"(\($0.map{"\($0)"}.joined(separator:",")))"}.joined()
        return desc.isEmpty ? "id" : desc
    }
    
    public var hashValue: Int {
        return elements.count > 0 ? elements[0].hashValue + 1 : 0
    }
}
