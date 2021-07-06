//
//  File.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/05/31.
//

import SwmCore

public struct Braid<n: SizeType>: MathSet, Multiplicative, CustomStringConvertible {
    public typealias Element = (generator: Generator, sign: Int)
    public let strands: Int
    public let elements: [Element]
    
    fileprivate init(strands: Int, elements: [Element]) {
        assert(elements.allSatisfy{ $0.sign.abs == 1 })
        self.strands = strands
        self.elements = elements
    }
    
    public init(strands: Int, code: [Int]) {
        self.strands = strands
        self.elements = code.map { i in
            (Generator(i.abs), i.sign)
        }
    }
    
    public init(strands: Int, code: Int...) {
        self.init(strands: strands, code: code)
    }
    
    public static func generator(strands: Int, index: Int) -> Self {
        .init(strands: strands, elements: [ (Generator(index), index) ] )
    }
    
    public static func allGenerators(strands: Int) -> [Self] {
        (1 ... strands - 1).map{ generator(strands: strands, index: $0) }
    }
    
    public static func identity(strands: Int) -> Self {
        .init(strands: strands, elements: [])
    }
    
    public var inverse: Self? {
        .init(strands: strands, elements: elements.reversed().map{ (σ, e) in (σ, -e) })
    }
    
    public static func * (a: Braid<n>, b: Braid<n>) -> Braid<n> {
        assert(a.strands == b.strands)
        return .init(strands: a.strands, elements: a.elements + b.elements)
    }
    
    public static func == (a: Self, b: Self) -> Bool {
        a.strands == b.strands
            && a.elements.count == b.elements.count
            && (0 ..< a.elements.count).allSatisfy{ i in a.elements[i] == b.elements[i] }
    }
    
    public var description: String {
        return elements.reduce(""){ (res, s) in res + "\(s.0)\(s.1 == 1 ? "" : Format.sup(s.1))" }
    }
    
    public var detailDescription: String {
        func row(_ index: Int, _ sign: Int) -> String {
            var res = ""
            
            for r in 0 ..< 3 {
                for i in 1 ... strands {
                    switch i {
                    case index:
                        switch r {
                        case  0: res += "\\ /"
                        case  1: res += (sign > 0) ? " / " : " \\ "
                        default: res += "/ \\"
                        }
                    case index + 1: res += " "
                    default: res += "| "
                    }
                }
                res += "\n"
            }
            
            return res
        }
        
        return elements.map { (σ, e) in
            row(σ.index, e)
        }.joined()
    }
    
    // MEMO { σ_1 ... σ_{n - 1} } are the generators of Braid<n>
    public struct Generator: Equatable, CustomStringConvertible, ExpressibleByIntegerLiteral {
        public let index: Int
        
        public init(integerLiteral value: Int) {
            self.init(value)
        }
        
        public init(_ index: Int) {
            assert(1 <= index && index < n.intValue)
            self.index = index
        }
        
        public var description: String {
            "σ\(Format.sub(index))"
        }
    }
}

extension Braid: Monoid where n: FixedSizeType {
    public init(code: [Int]) {
        self.init(strands: n.intValue, code: code)
    }
    
    public init(code: Int...) {
        self.init(strands: n.intValue, code: code)
    }
    
    public static func generator(index: Int) -> Self {
        generator(strands: n.intValue, index: index)
    }
    
    public static var allGenerators: [Self] {
        allGenerators(strands: n.intValue)
    }
    
    public static var identity: Self {
        identity(strands: n.intValue)
    }
}

extension Braid {
    public var closure: Link {
        var edges = (0 ..< strands).toArray()
        var count = edges.count
        var pdCode: Link.PDCode = []
        
        for (s, e) in elements {
            /*        +       -
             *  ↓   a   b   a   b
             *       \ /     \ /
             *  ↓     /       \
             *       / \     / \
             *  ↓   c   d   c   d
             */
            let i = s.index
            let (a, b) = (edges[i - 1], edges[i])
            let (c, d) = (count, count + 1)
            
            if e == 1 {
                pdCode.append([a, c, d, b])
            } else {
                pdCode.append([b, a, c, d])
            }
            
            edges[i - 1] = c
            edges[i] = d
            count += 2
        }
        
        assert(
            edges.enumerated().allSatisfy{ (i, j) in i != j },
            "braid closure contains free loop."
        )
        
        // identify boundary points.
        
        let conn = Dictionary(zip(edges, 0 ..< strands))
        pdCode = pdCode.map { c in
            c.map { a in conn[a] ?? a }
        }
        
        return Link(name: description, pdCode: pdCode)
    }
}
