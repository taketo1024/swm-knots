//: Playground - noun: a place where people can play

import Foundation

typealias _2 = TPInt_2
typealias _3 = TPInt_3

let a = Matrix<Z, _3, _2>(2, 3, 1, 4, 2, 1)
let b = Matrix<Z, _2, _3>(3, 1, 2, 2, 4, 2)
let c = a * b

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
    
    public static var allElements: [SymGroup<n>] {
        func perm(n: Int) -> [[Int]] {
            return [[n], [n + 1]]
        }
        return []
    }
}

extension SymGroup: CustomStringConvertible {
    public var description: String {
        return "(" + (0 ..< degree).map({ i in
            return "\(i): \(self[i])"
        }).joinWithSeparator(", ") + ")"
    }
}

public func *<n: TPInt>(lhs: SymGroup<n>, rhs: SymGroup<n>) -> SymGroup<n> {
    return SymGroup{ lhs[rhs[$0]] }
}

let s: SymGroup<_3> = SymGroup(2, 0, 1)
let t: SymGroup<_3> = SymGroup(0, 2, 1)
let u = t * s

