//
//  File.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/05/31.
//

import SwmCore

public struct Braid<n: SizeType>: MathSet, Multiplicative, CustomStringConvertible {
    public let strands: Int
    public let elements: [(Generator, Int)]
    
    public init(strands: Int, elements: [(Generator, Int)]) {
        self.strands = strands
        self.elements = elements // TODO reduce
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
        (1 ... n.intValue - 1).map{ generator(strands: strands, index: $0) }
    }
    
    public static func identity(strands: Int) -> Self {
        .init(strands: strands, elements: [])
    }
    
    public var inverse: Self? {
        .init(strands: strands, elements: elements.reversed().map{ (σ, n) in (σ, -n) })
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
    
    public func describe() {
        func printRow(_ index: Int, _ sign: Int) {
            func printc(_ s: String) {
                print(s, terminator: "")
            }
            
            for r in 0 ..< 3 {
                for i in 1 ... n.intValue {
                    switch i {
                    case index:
                        switch r {
                        case  0: printc("\\ /")
                        case  1: printc((sign > 0) ? " / " : " \\ ")
                        default: printc("/ \\")
                        }
                    case index + 1: printc(" ")
                    default: printc("| ")
                    }
                }
                print()
            }
        }
        
        for (σ, p) in elements {
            for _ in 0 ..< p.abs {
                printRow(σ.index, p)
            }
        }
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
    public init(elements: [(Generator, Int)]) {
        self.init(strands: n.intValue, elements: elements)
    }
    
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
