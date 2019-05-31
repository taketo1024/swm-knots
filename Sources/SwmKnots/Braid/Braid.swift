//
//  File.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/05/31.
//

import SwmCore

public struct Braid<n: FixedSizeType>: Group {
    internal typealias Word = [(Generator, Int)]
    internal let word: Word
    
    internal init(_ word: Word) {
        // TODO reduce
        self.word = word
    }
    
    public static func produce(code: Int...) -> Braid<n> {
        assert(code.count.isEven)
        
        var word: Word = []
        for i in 0 ..< code.count / 2 {
            word.append( (Generator(code[2 * i]), code[2 * i + 1]) )
        }
        return Braid(word)
    }
    
    public static var strands: Int {
        return n.intValue
    }
    
    public static func generator(_ index: Int) -> Braid<n> {
        return Braid( [ (Generator(index), index) ] )
    }
    
    public static var generators: [Braid<n>] {
        return (1 ... n.intValue - 1).map{ generator($0) }
    }
    
    public static var identity: Braid<n> {
        return Braid([])
    }
    
    public var inverse: Braid<n>? {
        return Braid(word.reversed().map{ (σ, n) in (σ, -n) })
    }
    
    public static func * (a: Braid<n>, b: Braid<n>) -> Braid<n> {
        return Braid(a.word + b.word)
    }
    
    public static func == (a: Braid<n>, b: Braid<n>) -> Bool {
        // TODO must consider relations
        
        // return lhs.word == rhs.word
        
        return a.word.count == b.word.count &&
            (0 ..< a.word.count).allSatisfy{ i in a.word[i] == b.word[i] }
    }
    
    public var description: String {
        return word.reduce(""){ (res, s) in res + "\(s.0)\(s.1 == 1 ? "" : Format.sup(s.1))" }
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
        
        for (σ, p) in word {
            for _ in 0 ..< p.abs {
                printRow(σ.index, p)
            }
        }
    }
    
    // MEMO { σ_1 ... σ_{n - 1} } are the generators of Braid<n>
    public struct Generator: Equatable, CustomStringConvertible {
        public let index: Int
        internal init(_ index: Int) {
            assert(1 <= index && index < n.intValue)
            self.index = index
        }
        
        public var description: String {
            return "σ\(Format.sub(index))"
        }
    }
}
